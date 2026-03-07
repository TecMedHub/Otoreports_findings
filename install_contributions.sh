#!/bin/bash
# ============================================================
# install_contributions.sh
# Gestor interactivo de contribuciones para OtoReports findings
# ============================================================

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ADD_DIR="$SCRIPT_DIR/add"
JSON_DIR="$SCRIPT_DIR/json"
IMG_DIR="$SCRIPT_DIR/img"
EQUIP_IMG_DIR="$SCRIPT_DIR/images/equipment"
EQUIP_JSON="$JSON_DIR/equipment.json"
INDEX_JSON="$JSON_DIR/index.json"
GITHUB_RAW="https://raw.githubusercontent.com/TecMedHub/Otoreports_findings/main"

# Registro de cambios pendientes de commit
PENDING_CHANGES=()

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}  [OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERR]${NC} $*"; }

separator() {
    echo -e "${DIM}$(printf '%.0s-' {1..50})${NC}"
}

pause() {
    echo ""
    read -rp "Presiona Enter para continuar..." _
}

# ============================================================
# Asegurar que exista add/
# ============================================================
ensure_add_dir() {
    if [ ! -d "$ADD_DIR" ]; then
        mkdir -p "$ADD_DIR"
        info "Carpeta add/ creada."
    fi
}

# ============================================================
# Utilidad: analizar un ZIP y poblar arrays globales
# ============================================================
analyze_zip() {
    local zip_file="$1"
    _az_image_files=()
    _az_json_files=()
    _az_other_files=()

    local contents
    contents="$(unzip -l "$zip_file" 2>/dev/null | tail -n +4 | head -n -2)"

    while IFS= read -r line; do
        local fname
        fname="$(echo "$line" | awk '{print $NF}')"
        [[ "$fname" == */ ]] && continue
        local base ext ext_lower
        base="$(basename "$fname")"
        ext="${base##*.}"
        ext_lower="$(echo "$ext" | tr '[:upper:]' '[:lower:]')"

        case "$ext_lower" in
            jpg|jpeg|png|webp|gif|bmp)
                _az_image_files+=("$fname")
                ;;
            json)
                _az_json_files+=("$fname")
                ;;
            *)
                _az_other_files+=("$fname")
                ;;
        esac
    done <<< "$contents"
}

# ============================================================
# 1. Listar ZIPs en add/
# ============================================================
menu_listar_zips() {
    ensure_add_dir
    echo ""
    echo -e "${BOLD}  Contenido de add/${NC}"
    separator

    shopt -s nullglob
    local zips=("$ADD_DIR"/*.zip)
    shopt -u nullglob

    if [ ${#zips[@]} -eq 0 ]; then
        warn "No hay archivos .zip en add/"
        pause
        return
    fi

    for i in "${!zips[@]}"; do
        local zip_file="${zips[$i]}"
        local zip_name size
        zip_name="$(basename "$zip_file")"
        size="$(du -h "$zip_file" | cut -f1)"

        echo -e "\n  ${BOLD}[$((i+1))] $zip_name${NC} ${DIM}($size)${NC}"

        analyze_zip "$zip_file"

        if [ ${#_az_image_files[@]} -gt 0 ]; then
            echo -e "      ${CYAN}Imagenes:${NC} ${#_az_image_files[@]}"
            for img in "${_az_image_files[@]}"; do
                echo -e "        ${DIM}- $(basename "$img")${NC}"
            done
        fi
        if [ ${#_az_json_files[@]} -gt 0 ]; then
            echo -e "      ${CYAN}JSON:${NC} ${#_az_json_files[@]}"
            for jf in "${_az_json_files[@]}"; do
                local bn
                bn="$(basename "$jf")"
                if [ "$bn" = "equipment.json" ]; then
                    echo -e "        ${YELLOW}- $bn (otoscopios)${NC}"
                elif [ "$bn" = "contributors.json" ] || [ "$bn" = "images.json" ]; then
                    echo -e "        ${YELLOW}- $bn (biblioteca)${NC}"
                else
                    echo -e "        ${DIM}- $bn${NC}"
                fi
            done
        fi
        if [ ${#_az_other_files[@]} -gt 0 ]; then
            echo -e "      ${DIM}Otros: ${#_az_other_files[@]} archivos${NC}"
        fi
    done
    echo ""
    pause
}

# ============================================================
# 2. Ver estado actual del sistema
# ============================================================
menu_estado_actual() {
    echo ""
    echo -e "${BOLD}  Estado actual del sistema${NC}"
    separator

    # Imagenes de biblioteca
    local lib_imgs=()
    while IFS= read -r -d '' f; do
        lib_imgs+=("$f")
    done < <(find "$IMG_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.bmp' \) -print0 2>/dev/null)
    echo -e "\n  ${CYAN}Biblioteca de imagenes (img/)${NC}"
    echo -e "    Imagenes: ${BOLD}${#lib_imgs[@]}${NC}"
    if [ ${#lib_imgs[@]} -gt 0 ]; then
        for f in "${lib_imgs[@]}"; do
            echo -e "      ${DIM}- $(basename "$f")${NC}"
        done
    fi

    # Equipamiento
    local equip_imgs=()
    while IFS= read -r -d '' f; do
        equip_imgs+=("$f")
    done < <(find "$EQUIP_IMG_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.bmp' \) -print0 2>/dev/null)
    echo -e "\n  ${CYAN}Imagenes de equipamiento (images/equipment/)${NC}"
    echo -e "    Imagenes: ${BOLD}${#equip_imgs[@]}${NC}"
    if [ ${#equip_imgs[@]} -gt 0 ]; then
        for f in "${equip_imgs[@]}"; do
            echo -e "      ${DIM}- $(basename "$f")${NC}"
        done
    fi

    # Otoscopios en equipment.json
    echo -e "\n  ${CYAN}Otoscopios registrados (equipment.json)${NC}"
    if command -v jq &>/dev/null && [ -f "$EQUIP_JSON" ]; then
        local count
        count="$(jq 'length' "$EQUIP_JSON")"
        echo -e "    Dispositivos: ${BOLD}$count${NC}"
        jq -r '.[] | "      - \(.name) (\(.price // "sin precio"))"' "$EQUIP_JSON"
    else
        echo "    (requiere jq para leer)"
    fi

    # Hallazgos en index.json
    echo -e "\n  ${CYAN}Hallazgos registrados (index.json)${NC}"
    if command -v jq &>/dev/null && [ -f "$INDEX_JSON" ]; then
        local findings_count contribs
        findings_count="$(jq '.findings | length' "$INDEX_JSON")"
        contribs="$(jq '.contributors | keys | length' "$INDEX_JSON")"
        echo -e "    Hallazgos: ${BOLD}$findings_count${NC}"
        echo -e "    Hallazgos con imagen: ${BOLD}$contribs${NC}"
        echo -e "    Contribuidores:"
        jq -r '.contributors | to_entries[] | .value[] | "      - \(.name)"' "$INDEX_JSON" 2>/dev/null | sort -u
    else
        echo "    (requiere jq para leer)"
    fi

    # Git status
    echo -e "\n  ${CYAN}Estado de git${NC}"
    cd "$SCRIPT_DIR"
    local status
    status="$(git status --short 2>/dev/null)"
    if [ -z "$status" ]; then
        echo -e "    ${GREEN}Limpio, sin cambios pendientes${NC}"
    else
        echo -e "    ${YELLOW}Cambios sin commitear:${NC}"
        echo "$status" | while IFS= read -r line; do
            echo "      $line"
        done
    fi

    # Cambios pendientes de esta sesion
    if [ ${#PENDING_CHANGES[@]} -gt 0 ]; then
        echo -e "\n  ${MAGENTA}Cambios de esta sesion (sin commit):${NC}"
        for ch in "${PENDING_CHANGES[@]}"; do
            echo -e "    - $ch"
        done
    fi

    echo ""
    pause
}

# ============================================================
# 3. Instalar contribuciones
# ============================================================
install_library_images() {
    local zip_file="$1" zip_name="$2"
    analyze_zip "$zip_file"

    if [ ${#_az_image_files[@]} -eq 0 ]; then
        warn "No hay imagenes en este ZIP."
        return
    fi

    local TEMP_DIR
    TEMP_DIR="$(mktemp -d)"
    unzip -qo "$zip_file" -d "$TEMP_DIR"

    local count=0
    for img in "${_az_image_files[@]}"; do
        local src="$TEMP_DIR/$img"
        [ ! -f "$src" ] && continue
        local dest_name
        dest_name="$(basename "$img")"

        if [ -f "$IMG_DIR/$dest_name" ]; then
            warn "  $dest_name ya existe en img/, sobreescribiendo"
        fi
        cp "$src" "$IMG_DIR/$dest_name"
        ok "$dest_name -> img/"
        count=$((count + 1))
    done

    # Mergear contributors si hay
    for jf in "${_az_json_files[@]}"; do
        local base_jf src_jf
        base_jf="$(basename "$jf")"
        src_jf="$TEMP_DIR/$jf"
        [ ! -f "$src_jf" ] && continue
        if [ "$base_jf" = "contributors.json" ] || [ "$base_jf" = "images.json" ]; then
            if command -v jq &>/dev/null; then
                local tmp_merged
                tmp_merged="$(mktemp)"
                jq -s '.[0].contributors as $old |
                       .[1] as $new |
                       .[0] | .contributors = ($old * $new)' \
                       "$INDEX_JSON" "$src_jf" > "$tmp_merged"
                cp "$tmp_merged" "$INDEX_JSON"
                rm "$tmp_merged"
                ok "Contribuidores mergeados en index.json"
            else
                warn "jq no disponible, merge manual necesario"
            fi
        fi
    done

    rm -rf "$TEMP_DIR"

    if [ $count -gt 0 ]; then
        PENDING_CHANGES+=("Imagenes biblioteca ($count) desde $zip_name")
        ok "Total: $count imagen(es) instaladas en biblioteca"
    fi
}

install_equipment() {
    local zip_file="$1" zip_name="$2"
    analyze_zip "$zip_file"

    local TEMP_DIR
    TEMP_DIR="$(mktemp -d)"
    unzip -qo "$zip_file" -d "$TEMP_DIR"

    local img_count=0
    for img in "${_az_image_files[@]}"; do
        local src="$TEMP_DIR/$img"
        [ ! -f "$src" ] && continue
        local dest_name
        dest_name="$(basename "$img")"
        mkdir -p "$EQUIP_IMG_DIR"

        if [ -f "$EQUIP_IMG_DIR/$dest_name" ]; then
            warn "  $dest_name ya existe en images/equipment/, sobreescribiendo"
        fi
        cp "$src" "$EQUIP_IMG_DIR/$dest_name"
        ok "$dest_name -> images/equipment/"
        img_count=$((img_count + 1))
    done

    for jf in "${_az_json_files[@]}"; do
        local base_jf src_jf
        base_jf="$(basename "$jf")"
        src_jf="$TEMP_DIR/$jf"
        [ ! -f "$src_jf" ] && continue
        if [ "$base_jf" = "equipment.json" ]; then
            if command -v jq &>/dev/null; then
                # Mostrar que se va a agregar
                echo ""
                info "Nuevos otoscopios a agregar:"
                jq -r '.[] | "    - \(.name) (\(.price // "sin precio"))"' "$src_jf"
                echo ""

                local tmp_merged
                tmp_merged="$(mktemp)"
                jq -s '.[0] + .[1]' "$EQUIP_JSON" "$src_jf" > "$tmp_merged"
                cp "$tmp_merged" "$EQUIP_JSON"
                rm "$tmp_merged"
                ok "Otoscopios mergeados en equipment.json"
            else
                warn "jq no disponible, merge manual necesario"
            fi
        fi
    done

    rm -rf "$TEMP_DIR"

    if [ $img_count -gt 0 ]; then
        PENDING_CHANGES+=("Equipamiento ($img_count img) desde $zip_name")
        ok "Total: $img_count imagen(es) de equipamiento instaladas"
    fi
}

# Instalar un ZIP con metadata automaticamente
install_with_metadata() {
    local zip_file="$1" zip_name="$2"

    local TEMP_DIR
    TEMP_DIR="$(mktemp -d)"
    unzip -qo "$zip_file" -d "$TEMP_DIR"

    local meta_file="$TEMP_DIR/metadata.json"

    local finding_key file_name contributor_name timestamp
    finding_key="$(jq -r '.findingKey // ""' "$meta_file")"
    file_name="$(jq -r '.file // ""' "$meta_file")"
    contributor_name="$(jq -r '.contributorName // ""' "$meta_file")"
    timestamp="$(jq -r '.timestamp // ""' "$meta_file")"

    echo -e "  ${CYAN}Hallazgo:${NC}      ${BOLD}$finding_key${NC}"
    echo -e "  ${CYAN}Archivo:${NC}       $file_name"
    echo -e "  ${CYAN}Contribuidor:${NC}  $contributor_name"
    echo -e "  ${CYAN}Fecha:${NC}         ${DIM}$timestamp${NC}"

    # Annotations
    if [ -f "$TEMP_DIR/annotations.json" ]; then
        local ann_count rotation crop bg
        ann_count="$(jq '.annotations | length' "$TEMP_DIR/annotations.json" 2>/dev/null || echo 0)"
        rotation="$(jq -r '.rotation // 0' "$TEMP_DIR/annotations.json" 2>/dev/null)"
        bg="$(jq -r '.background // "none"' "$TEMP_DIR/annotations.json" 2>/dev/null)"
        echo -e "  ${CYAN}Anotaciones:${NC}   $ann_count | rot: $rotation | fondo: $bg"
    fi

    # Verificar si el hallazgo existe
    if [ -n "$finding_key" ]; then
        if ! jq -e --arg k "$finding_key" '.findings[] | select(.key == $k)' "$INDEX_JSON" &>/dev/null; then
            warn "  Hallazgo '$finding_key' no existe en index.json"
        fi
    fi

    # Verificar si ya esta instalado
    local already=false
    if [ -n "$finding_key" ] && [ -n "$file_name" ]; then
        if jq -e --arg k "$finding_key" --arg f "$file_name" \
            '.contributors[$k] // [] | any(.file == $f)' "$INDEX_JSON" 2>/dev/null | grep -q true; then
            already=true
            echo -e "  ${YELLOW}Ya instalada previamente${NC}"
        fi
    fi

    echo ""

    if $already; then
        read -rp "  Reinstalar de todas formas? [s/n]: " confirm
        if [ "$confirm" != "s" ] && [ "$confirm" != "S" ]; then
            rm -rf "$TEMP_DIR"
            return
        fi
    fi

    # Copiar imagen
    if [ -n "$file_name" ] && [ -f "$TEMP_DIR/$file_name" ]; then
        cp "$TEMP_DIR/$file_name" "$IMG_DIR/$file_name"
        ok "$file_name -> img/"
    fi

    # Copiar annotations si existe
    if [ -f "$TEMP_DIR/annotations.json" ] && [ -n "$finding_key" ]; then
        local ann_dir="$SCRIPT_DIR/annotations"
        mkdir -p "$ann_dir"
        cp "$TEMP_DIR/annotations.json" "$ann_dir/${finding_key}.json"
        ok "annotations -> annotations/${finding_key}.json"
    fi

    # Registrar en index.json
    if [ -n "$finding_key" ] && [ -n "$file_name" ] && command -v jq &>/dev/null; then
        if ! $already; then
            local tmp
            tmp="$(mktemp)"
            jq --arg k "$finding_key" --arg name "$contributor_name" --arg file "$file_name" '
                if .contributors[$k] then
                    .contributors[$k] += [{ file: $file, name: $name }]
                else
                    .contributors[$k] = [{ file: $file, name: $name }]
                end
            ' "$INDEX_JSON" > "$tmp"
            cp "$tmp" "$INDEX_JSON"
            rm "$tmp"
            ok "Registrado en index.json: $finding_key ($contributor_name)"
        fi
    fi

    rm -rf "$TEMP_DIR"
    PENDING_CHANGES+=("$finding_key: $file_name ($contributor_name) desde $zip_name")
}

menu_instalar() {
    ensure_add_dir
    echo ""
    echo -e "${BOLD}  Instalar contribuciones${NC}"
    separator

    shopt -s nullglob
    local zips=("$ADD_DIR"/*.zip)
    shopt -u nullglob

    if [ ${#zips[@]} -eq 0 ]; then
        warn "No hay archivos .zip en add/"
        pause
        return
    fi

    # Analizar todos los ZIPs y clasificar
    local meta_zips=()      # ZIPs con metadata.json
    local equip_zips=()     # ZIPs con equipment.json
    local other_zips=()     # ZIPs sin clasificar

    for zip_file in "${zips[@]}"; do
        local contents
        contents="$(unzip -l "$zip_file" 2>/dev/null)"
        if echo "$contents" | grep -q "metadata.json"; then
            meta_zips+=("$zip_file")
        elif echo "$contents" | grep -q "equipment.json"; then
            equip_zips+=("$zip_file")
        else
            other_zips+=("$zip_file")
        fi
    done

    # Mostrar resumen
    echo ""
    if [ ${#meta_zips[@]} -gt 0 ]; then
        echo -e "  ${GREEN}Contribuciones con metadata: ${BOLD}${#meta_zips[@]}${NC}"
        for zf in "${meta_zips[@]}"; do
            local zn TMPD fkey fname cname
            zn="$(basename "$zf")"
            TMPD="$(mktemp -d)"
            unzip -qo "$zf" -d "$TMPD" metadata.json 2>/dev/null
            if [ -f "$TMPD/metadata.json" ]; then
                fkey="$(jq -r '.findingKey // "?"' "$TMPD/metadata.json")"
                fname="$(jq -r '.file // "?"' "$TMPD/metadata.json")"
                cname="$(jq -r '.contributorName // "?"' "$TMPD/metadata.json")"
                echo -e "    ${DIM}-${NC} $zn ${DIM}-> $fkey ($cname)${NC}"
            fi
            rm -rf "$TMPD"
        done
    fi
    if [ ${#equip_zips[@]} -gt 0 ]; then
        echo -e "  ${CYAN}Equipamiento: ${BOLD}${#equip_zips[@]}${NC}"
        for zf in "${equip_zips[@]}"; do
            echo -e "    ${DIM}- $(basename "$zf")${NC}"
        done
    fi
    if [ ${#other_zips[@]} -gt 0 ]; then
        echo -e "  ${YELLOW}Sin clasificar: ${BOLD}${#other_zips[@]}${NC}"
        for zf in "${other_zips[@]}"; do
            echo -e "    ${DIM}- $(basename "$zf")${NC}"
        done
    fi

    echo ""
    echo -e "  ${BOLD}a)${NC} Instalar TODAS las contribuciones con metadata"
    echo -e "  ${BOLD}b)${NC} Instalar un ZIP especifico"
    echo -e "  ${BOLD}c)${NC} Instalar equipamiento"
    echo -e "  ${BOLD}0)${NC} Volver"
    echo ""
    read -rp "  Opcion: " choice

    case "$choice" in
        a|A)
            if [ ${#meta_zips[@]} -eq 0 ]; then
                warn "No hay ZIPs con metadata"
                pause
                return
            fi
            echo ""
            for zf in "${meta_zips[@]}"; do
                local zn
                zn="$(basename "$zf")"
                echo -e "  ${BOLD}$zn${NC}"
                separator
                install_with_metadata "$zf" "$zn"
                echo ""
            done
            ok "Todas las contribuciones con metadata instaladas"
            ;;
        b|B)
            echo ""
            for i in "${!zips[@]}"; do
                echo "  [$((i+1))] $(basename "${zips[$i]}")"
            done
            echo "  [0] Volver"
            echo ""
            read -rp "  Selecciona un ZIP: " sel

            [ "$sel" = "0" ] && { pause; return; }
            if ! [[ "$sel" =~ ^[0-9]+$ ]] || [ "$sel" -lt 1 ] || [ "$sel" -gt ${#zips[@]} ]; then
                error "Seleccion invalida"
                pause
                return
            fi

            local zip_file="${zips[$((sel-1))]}"
            local zip_name
            zip_name="$(basename "$zip_file")"

            echo ""
            echo -e "  ${BOLD}$zip_name${NC}"
            separator

            # Detectar tipo
            local TEMP_DIR
            TEMP_DIR="$(mktemp -d)"
            unzip -qo "$zip_file" -d "$TEMP_DIR"

            if [ -f "$TEMP_DIR/metadata.json" ]; then
                echo -e "  ${GREEN}Tipo: Contribucion con metadata${NC}"
                echo ""
                install_with_metadata "$zip_file" "$zip_name"
            elif [ -f "$TEMP_DIR/equipment.json" ]; then
                echo -e "  ${CYAN}Tipo: Equipamiento${NC}"
                echo ""
                rm -rf "$TEMP_DIR"
                install_equipment "$zip_file" "$zip_name"
            else
                echo -e "  ${YELLOW}Tipo: Sin metadata${NC}"
                echo ""
                analyze_zip "$zip_file"
                echo ""
                echo "  Donde instalar?"
                echo "    1) Biblioteca de hallazgos (img/)"
                echo "    2) Equipamiento (images/equipment/)"
                echo "    0) Cancelar"
                echo ""
                read -rp "  Opcion: " sub
                rm -rf "$TEMP_DIR"
                case "$sub" in
                    1) install_library_images "$zip_file" "$zip_name" ;;
                    2) install_equipment "$zip_file" "$zip_name" ;;
                esac
            fi
            [ -d "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"
            ;;
        c|C)
            if [ ${#equip_zips[@]} -eq 0 ]; then
                warn "No hay ZIPs de equipamiento"
                pause
                return
            fi
            for zf in "${equip_zips[@]}"; do
                local zn
                zn="$(basename "$zf")"
                echo ""
                echo -e "  ${BOLD}$zn${NC}"
                separator
                install_equipment "$zf" "$zn"
            done
            ;;
        0) return ;;
    esac
    pause
}

# ============================================================
# 4. Editar contribuciones existentes
# ============================================================
menu_editar() {
    echo ""
    echo -e "${BOLD}  Editar contribuciones${NC}"
    separator
    echo ""
    echo -e "  ${BOLD}Biblioteca${NC}"
    echo -e "    a) Eliminar imagen de la biblioteca (img/)"
    echo -e "    b) Renombrar imagen de la biblioteca"
    echo ""
    echo -e "  ${BOLD}Equipamiento${NC}"
    echo -e "    c) Eliminar otoscopio de equipment.json"
    echo -e "    d) Editar otoscopio (nombre, precio, link, comentarios)"
    echo -e "    e) Eliminar imagen de equipamiento"
    echo ""
    echo -e "  ${BOLD}Contribuidores${NC}"
    echo -e "    f) Gestionar contribuciones (ver, agregar, editar, eliminar)"
    echo ""
    echo -e "    0) Volver"
    echo ""
    read -rp "  Opcion: " choice

    case "$choice" in
        a|A) editar_eliminar_img_biblioteca ;;
        b|B) editar_renombrar_img_biblioteca ;;
        c|C) editar_eliminar_otoscopio ;;
        d|D) editar_otoscopio ;;
        e|E) editar_eliminar_img_equip ;;
        f|F) menu_contribuciones ;;
        0) return ;;
        *) warn "Opcion no valida" ;;
    esac
    pause
}

# --- a) Eliminar imagen de biblioteca ---
editar_eliminar_img_biblioteca() {
    local imgs=()
    while IFS= read -r -d '' f; do
        imgs+=("$f")
    done < <(find "$IMG_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.bmp' \) -print0 2>/dev/null | sort -z)

    if [ ${#imgs[@]} -eq 0 ]; then
        info "No hay imagenes en la biblioteca."
        return
    fi

    echo ""
    for i in "${!imgs[@]}"; do
        echo "  [$((i+1))] $(basename "${imgs[$i]}")"
    done
    echo ""
    read -rp "  Numero de imagen a eliminar (0=cancelar): " sel

    [ "$sel" = "0" ] && return
    if ! [[ "$sel" =~ ^[0-9]+$ ]] || [ "$sel" -lt 1 ] || [ "$sel" -gt ${#imgs[@]} ]; then
        error "Seleccion invalida"
        return
    fi

    local target="${imgs[$((sel-1))]}"
    local name
    name="$(basename "$target")"
    read -rp "  Eliminar $name? [s/n]: " confirm
    if [ "$confirm" = "s" ] || [ "$confirm" = "S" ]; then
        rm "$target"
        ok "$name eliminada"
        PENDING_CHANGES+=("Eliminada imagen biblioteca: $name")
    fi
}

# --- b) Renombrar imagen de biblioteca ---
editar_renombrar_img_biblioteca() {
    local imgs=()
    while IFS= read -r -d '' f; do
        imgs+=("$f")
    done < <(find "$IMG_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.bmp' \) -print0 2>/dev/null | sort -z)

    if [ ${#imgs[@]} -eq 0 ]; then
        info "No hay imagenes en la biblioteca."
        return
    fi

    echo ""
    for i in "${!imgs[@]}"; do
        echo "  [$((i+1))] $(basename "${imgs[$i]}")"
    done
    echo ""
    read -rp "  Numero de imagen a renombrar (0=cancelar): " sel

    [ "$sel" = "0" ] && return
    if ! [[ "$sel" =~ ^[0-9]+$ ]] || [ "$sel" -lt 1 ] || [ "$sel" -gt ${#imgs[@]} ]; then
        error "Seleccion invalida"
        return
    fi

    local target="${imgs[$((sel-1))]}"
    local old_name
    old_name="$(basename "$target")"
    local ext="${old_name##*.}"

    echo ""
    read -rp "  Nuevo nombre (sin extension, se mantiene .$ext): " new_base
    if [ -z "$new_base" ]; then
        warn "Nombre vacio, cancelando"
        return
    fi

    local new_name="${new_base}.${ext}"
    if [ -f "$IMG_DIR/$new_name" ]; then
        error "$new_name ya existe"
        return
    fi

    mv "$target" "$IMG_DIR/$new_name"
    ok "$old_name -> $new_name"

    # Actualizar index.json si la imagen estaba referenciada
    if command -v jq &>/dev/null; then
        if jq -e --arg old "$old_name" '.contributors | to_entries[] | .value[] | select(.file == $old)' "$INDEX_JSON" &>/dev/null; then
            local tmp
            tmp="$(mktemp)"
            jq --arg old "$old_name" --arg new "$new_name" '
                .contributors |= with_entries(
                    .value |= map(if .file == $old then .file = $new else . end)
                )' "$INDEX_JSON" > "$tmp"
            cp "$tmp" "$INDEX_JSON"
            rm "$tmp"
            ok "Referencia actualizada en index.json"
        fi
    fi
    PENDING_CHANGES+=("Renombrada: $old_name -> $new_name")
}

# --- c) Eliminar otoscopio ---
editar_eliminar_otoscopio() {
    if ! command -v jq &>/dev/null; then
        error "Se requiere jq para esta operacion"
        return
    fi

    local count
    count="$(jq 'length' "$EQUIP_JSON")"
    if [ "$count" -eq 0 ]; then
        info "No hay otoscopios registrados."
        return
    fi

    echo ""
    jq -r 'to_entries[] | "  [\(.key + 1)] \(.value.name) (\(.value.price // "sin precio"))"' "$EQUIP_JSON"
    echo ""
    read -rp "  Numero de otoscopio a eliminar (0=cancelar): " sel

    [ "$sel" = "0" ] && return
    if ! [[ "$sel" =~ ^[0-9]+$ ]] || [ "$sel" -lt 1 ] || [ "$sel" -gt "$count" ]; then
        error "Seleccion invalida"
        return
    fi

    local idx=$((sel - 1))
    local name
    name="$(jq -r ".[$idx].name" "$EQUIP_JSON")"

    read -rp "  Eliminar '$name'? [s/n]: " confirm
    if [ "$confirm" = "s" ] || [ "$confirm" = "S" ]; then
        local tmp
        tmp="$(mktemp)"
        jq "del(.[$idx])" "$EQUIP_JSON" > "$tmp"
        cp "$tmp" "$EQUIP_JSON"
        rm "$tmp"
        ok "'$name' eliminado de equipment.json"
        PENDING_CHANGES+=("Eliminado otoscopio: $name")
    fi
}

# --- d) Editar otoscopio ---
editar_otoscopio() {
    if ! command -v jq &>/dev/null; then
        error "Se requiere jq para esta operacion"
        return
    fi

    local count
    count="$(jq 'length' "$EQUIP_JSON")"
    if [ "$count" -eq 0 ]; then
        info "No hay otoscopios registrados."
        return
    fi

    echo ""
    jq -r 'to_entries[] | "  [\(.key + 1)] \(.value.name)"' "$EQUIP_JSON"
    echo ""
    read -rp "  Numero de otoscopio a editar (0=cancelar): " sel

    [ "$sel" = "0" ] && return
    if ! [[ "$sel" =~ ^[0-9]+$ ]] || [ "$sel" -lt 1 ] || [ "$sel" -gt "$count" ]; then
        error "Seleccion invalida"
        return
    fi

    local idx=$((sel - 1))
    echo ""
    echo -e "  ${CYAN}Datos actuales:${NC}"
    jq ".[$idx]" "$EQUIP_JSON"

    local name price link comment_es comment_en image
    name="$(jq -r ".[$idx].name" "$EQUIP_JSON")"
    price="$(jq -r ".[$idx].price // \"\"" "$EQUIP_JSON")"
    link="$(jq -r ".[$idx].link // \"\"" "$EQUIP_JSON")"
    comment_es="$(jq -r ".[$idx].comments.es // \"\"" "$EQUIP_JSON")"
    comment_en="$(jq -r ".[$idx].comments.en // \"\"" "$EQUIP_JSON")"
    image="$(jq -r ".[$idx].image // \"\"" "$EQUIP_JSON")"

    echo ""
    info "Deja vacio para mantener el valor actual"
    echo ""

    read -rp "  Nombre [$name]: " new_name
    read -rp "  Precio [$price]: " new_price
    read -rp "  Link [$link]: " new_link
    read -rp "  Comentario ES [$comment_es]: " new_ces
    read -rp "  Comentario EN [$comment_en]: " new_cen
    read -rp "  URL imagen [$image]: " new_image

    [ -n "$new_name" ] && name="$new_name"
    [ -n "$new_price" ] && price="$new_price"
    [ -n "$new_link" ] && link="$new_link"
    [ -n "$new_ces" ] && comment_es="$new_ces"
    [ -n "$new_cen" ] && comment_en="$new_cen"
    [ -n "$new_image" ] && image="$new_image"

    local tmp
    tmp="$(mktemp)"
    jq --arg name "$name" --arg price "$price" --arg link "$link" \
       --arg ces "$comment_es" --arg cen "$comment_en" --arg img "$image" \
       --argjson idx "$idx" '
        .[$idx] = {
            name: $name,
            comments: { es: $ces, en: $cen },
            price: $price,
            link: $link,
            image: $img
        }' "$EQUIP_JSON" > "$tmp"
    cp "$tmp" "$EQUIP_JSON"
    rm "$tmp"
    ok "'$name' actualizado"
    PENDING_CHANGES+=("Editado otoscopio: $name")
}

# --- e) Eliminar imagen de equipamiento ---
editar_eliminar_img_equip() {
    local imgs=()
    while IFS= read -r -d '' f; do
        imgs+=("$f")
    done < <(find "$EQUIP_IMG_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.bmp' \) -print0 2>/dev/null | sort -z)

    if [ ${#imgs[@]} -eq 0 ]; then
        info "No hay imagenes de equipamiento."
        return
    fi

    echo ""
    for i in "${!imgs[@]}"; do
        echo "  [$((i+1))] $(basename "${imgs[$i]}")"
    done
    echo ""
    read -rp "  Numero de imagen a eliminar (0=cancelar): " sel

    [ "$sel" = "0" ] && return
    if ! [[ "$sel" =~ ^[0-9]+$ ]] || [ "$sel" -lt 1 ] || [ "$sel" -gt ${#imgs[@]} ]; then
        error "Seleccion invalida"
        return
    fi

    local target="${imgs[$((sel-1))]}"
    local name
    name="$(basename "$target")"
    read -rp "  Eliminar $name? [s/n]: " confirm
    if [ "$confirm" = "s" ] || [ "$confirm" = "S" ]; then
        rm "$target"
        ok "$name eliminada"
        PENDING_CHANGES+=("Eliminada imagen equipamiento: $name")
    fi
}

# --- f) Gestor de contribuciones ---

# Utilidad: selector de hallazgo con busqueda y paginacion
seleccionar_hallazgo() {
    # Retorna el key seleccionado en $_selected_finding
    _selected_finding=""

    if ! command -v jq &>/dev/null; then
        error "Se requiere jq"
        return 1
    fi

    local all_keys=()
    while IFS= read -r k; do
        all_keys+=("$k")
    done < <(jq -r '.findings[].key' "$INDEX_JSON")

    local total=${#all_keys[@]}
    local page_size=20
    local page=0
    local max_page=$(( (total - 1) / page_size ))

    while true; do
        local start=$((page * page_size))
        local end=$((start + page_size))
        [ $end -gt $total ] && end=$total

        echo ""
        echo -e "  ${BOLD}Hallazgos disponibles${NC} ${DIM}(pag $((page+1))/$((max_page+1)), total: $total)${NC}"
        separator

        # Mostrar hallazgos con indicador si tienen contribuciones
        for ((i=start; i<end; i++)); do
            local key="${all_keys[$i]}"
            local has_contrib=""
            if jq -e --arg k "$key" '.contributors[$k] // empty' "$INDEX_JSON" &>/dev/null; then
                has_contrib="${GREEN}*${NC}"
            fi
            local cat
            cat="$(jq -r --arg k "$key" '.findings[] | select(.key == $k) | .category' "$INDEX_JSON")"
            printf "  ${BOLD}%3d)${NC} %-35s ${DIM}[%s]${NC} %b\n" "$((i+1))" "$key" "$cat" "$has_contrib"
        done

        echo ""
        echo -e "  ${DIM}[*] = tiene contribuciones${NC}"
        echo ""
        echo -e "  ${DIM}n=siguiente  p=anterior  /texto=buscar  0=cancelar${NC}"
        echo ""
        read -rp "  Numero o comando: " input

        case "$input" in
            0) return 1 ;;
            n|N)
                [ $page -lt $max_page ] && page=$((page+1))
                ;;
            p|P)
                [ $page -gt 0 ] && page=$((page-1))
                ;;
            /*)
                # Busqueda
                local search="${input:1}"
                local matches=()
                for k in "${all_keys[@]}"; do
                    if echo "$k" | grep -qi "$search"; then
                        matches+=("$k")
                    fi
                done
                if [ ${#matches[@]} -eq 0 ]; then
                    warn "Sin resultados para '$search'"
                else
                    echo ""
                    echo -e "  ${CYAN}Resultados para '$search':${NC}"
                    for i in "${!matches[@]}"; do
                        local key="${matches[$i]}"
                        local has_contrib=""
                        if jq -e --arg k "$key" '.contributors[$k] // empty' "$INDEX_JSON" &>/dev/null; then
                            has_contrib="${GREEN}*${NC}"
                        fi
                        printf "  ${BOLD}%3d)${NC} %-35s %b\n" "$((i+1))" "$key" "$has_contrib"
                    done
                    echo ""
                    read -rp "  Seleccionar numero (0=volver a lista): " msel
                    if [[ "$msel" =~ ^[0-9]+$ ]] && [ "$msel" -ge 1 ] && [ "$msel" -le ${#matches[@]} ]; then
                        _selected_finding="${matches[$((msel-1))]}"
                        return 0
                    fi
                fi
                ;;
            *)
                if [[ "$input" =~ ^[0-9]+$ ]] && [ "$input" -ge 1 ] && [ "$input" -le "$total" ]; then
                    _selected_finding="${all_keys[$((input-1))]}"
                    return 0
                else
                    warn "Entrada no valida"
                fi
                ;;
        esac
    done
}

# Mostrar detalle de una contribucion
mostrar_contribucion() {
    local key="$1"
    echo ""
    echo -e "  ${BOLD}${CYAN}Contribucion: $key${NC}"
    separator

    local cat
    cat="$(jq -r --arg k "$key" '.findings[] | select(.key == $k) | .category' "$INDEX_JSON")"
    echo -e "  Categoria: ${BOLD}$cat${NC}"

    if jq -e --arg k "$key" '.contributors[$k] // empty' "$INDEX_JSON" &>/dev/null; then
        local count
        count="$(jq --arg k "$key" '.contributors[$k] | length' "$INDEX_JSON")"
        echo -e "  Entradas: ${BOLD}$count${NC}"
        echo ""
        jq -r --arg k "$key" '.contributors[$k] | to_entries[] |
            "  [\(.key + 1)] Nombre: \(.value.name // "(vacio)")\n      Archivo: \(.value.file // "(vacio)")"' "$INDEX_JSON"
    else
        echo -e "  ${DIM}Sin contribuciones registradas${NC}"
    fi
    echo ""
}

menu_contribuciones() {
    if ! command -v jq &>/dev/null; then
        error "Se requiere jq para esta operacion"
        return
    fi

    while true; do
        echo ""
        echo -e "${BOLD}  Gestor de contribuciones${NC}"
        separator

        # Resumen rapido
        local total_findings total_with_contribs total_entries
        total_findings="$(jq '.findings | length' "$INDEX_JSON")"
        total_with_contribs="$(jq '[.contributors | to_entries[] | select(.value | type == "array")] | length' "$INDEX_JSON")"
        total_entries="$(jq '[.contributors | to_entries[] | select(.value | type == "array") | .value[]] | length' "$INDEX_JSON")"

        echo ""
        echo -e "  Hallazgos totales:     ${BOLD}$total_findings${NC}"
        echo -e "  Con contribuciones:    ${BOLD}$total_with_contribs${NC}"
        echo -e "  Entradas totales:      ${BOLD}$total_entries${NC}"

        # Detectar imagenes sin registrar
        local registered_files
        registered_files="$(jq -r '[.contributors | to_entries[] | select(.value | type == "array") | .value[].file] | .[]' "$INDEX_JSON" 2>/dev/null)"
        local unregistered=()
        while IFS= read -r -d '' f; do
            local bname
            bname="$(basename "$f")"
            if ! echo "$registered_files" | grep -qxF "$bname"; then
                unregistered+=("$bname")
            fi
        done < <(find "$IMG_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.bmp' \) -print0 2>/dev/null | sort -z)

        echo -e "  Imagenes en img/:      ${BOLD}$(( ${#unregistered[@]} + $(echo "$registered_files" | grep -c . 2>/dev/null || echo 0) ))${NC}"

        if [ ${#unregistered[@]} -gt 0 ]; then
            echo ""
            echo -e "  ${YELLOW}Imagenes sin registrar:${NC}"
            for uf in "${unregistered[@]}"; do
                echo -e "    ${RED}!${NC} $uf"
            done
        fi

        # Listar los que tienen contribuciones
        local keys
        keys="$(jq -r '[.contributors | to_entries[] | select(.value | type == "array")] | .[].key' "$INDEX_JSON" 2>/dev/null)"
        if [ -n "$keys" ]; then
            echo ""
            echo -e "  ${CYAN}Hallazgos con contribuciones:${NC}"
            while IFS= read -r key; do
                local count names
                count="$(jq --arg k "$key" '.contributors[$k] | length' "$INDEX_JSON")"
                names="$(jq -r --arg k "$key" '.contributors[$k][] | .name // "(sin nombre)"' "$INDEX_JSON" | paste -sd', ')"
                echo -e "    ${BOLD}$key${NC} ($count): $names"
            done <<< "$keys"
        fi

        echo ""
        echo -e "  ${BOLD}a)${NC} Ver/editar contribucion existente"
        echo -e "  ${BOLD}b)${NC} Agregar contribucion a un hallazgo"
        echo -e "  ${BOLD}c)${NC} Eliminar entrada de un hallazgo"
        echo -e "  ${BOLD}d)${NC} Mover contribucion a otro hallazgo"
        echo -e "  ${BOLD}e)${NC} Registrar imagenes sin asignar"
        echo ""
        echo -e "  ${BOLD}0)${NC} Volver"
        echo ""
        read -rp "  Opcion: " choice

        case "$choice" in
            a|A) contrib_ver_editar ;;
            b|B) contrib_agregar ;;
            c|C) contrib_eliminar ;;
            d|D) contrib_mover ;;
            e|E) contrib_registrar_sin_asignar ;;
            0) return ;;
            *) warn "Opcion no valida" ;;
        esac
    done
}

# --- a) Ver y editar contribucion ---
contrib_ver_editar() {
    echo ""
    info "Selecciona el hallazgo a ver/editar"

    if ! seleccionar_hallazgo; then
        return
    fi

    local key="$_selected_finding"
    mostrar_contribucion "$key"

    if ! jq -e --arg k "$key" '.contributors[$k] // empty' "$INDEX_JSON" &>/dev/null; then
        info "No hay entradas para editar en '$key'"
        read -rp "  Agregar una? [s/n]: " confirm
        if [ "$confirm" = "s" ] || [ "$confirm" = "S" ]; then
            contrib_agregar_a "$key"
        fi
        return
    fi

    local count
    count="$(jq --arg k "$key" '.contributors[$k] | length' "$INDEX_JSON")"

    echo ""
    read -rp "  Numero de entrada a editar (0=volver): " sel

    [ "$sel" = "0" ] && return
    if ! [[ "$sel" =~ ^[0-9]+$ ]] || [ "$sel" -lt 1 ] || [ "$sel" -gt "$count" ]; then
        error "Seleccion invalida"
        return
    fi

    local idx=$((sel - 1))
    local cur_name cur_file
    cur_name="$(jq -r --arg k "$key" --argjson i "$idx" '.contributors[$k][$i].name // ""' "$INDEX_JSON")"
    cur_file="$(jq -r --arg k "$key" --argjson i "$idx" '.contributors[$k][$i].file // ""' "$INDEX_JSON")"

    echo ""
    echo -e "  ${CYAN}Editando entrada $sel de '$key'${NC}"
    separator
    echo -e "  Nombre actual: ${BOLD}${cur_name:-(vacio)}${NC}"
    echo -e "  Archivo actual: ${BOLD}${cur_file:-(vacio)}${NC}"
    echo ""
    info "Deja vacio para mantener el valor actual"
    echo ""

    read -rp "  Nombre [$cur_name]: " new_name
    read -rp "  Archivo [$cur_file]: " new_file

    [ -n "$new_name" ] && cur_name="$new_name"
    [ -n "$new_file" ] && cur_file="$new_file"

    local tmp
    tmp="$(mktemp)"
    jq --arg k "$key" --argjson i "$idx" --arg name "$cur_name" --arg file "$cur_file" '
        .contributors[$k][$i] = { file: $file, name: $name }
    ' "$INDEX_JSON" > "$tmp"
    cp "$tmp" "$INDEX_JSON"
    rm "$tmp"

    ok "Entrada actualizada en '$key'"
    PENDING_CHANGES+=("Editado contribuidor: $cur_name en $key")
}

# --- b) Agregar contribucion ---
contrib_agregar() {
    echo ""
    info "Selecciona el hallazgo donde agregar"

    if ! seleccionar_hallazgo; then
        return
    fi

    contrib_agregar_a "$_selected_finding"
}

contrib_agregar_a() {
    local key="$1"

    echo ""
    echo -e "  ${CYAN}Agregar contribucion a '$key'${NC}"
    separator

    # Mostrar imagenes disponibles en img/
    echo ""
    echo -e "  ${DIM}Imagenes disponibles en img/:${NC}"
    local imgs=()
    while IFS= read -r -d '' f; do
        imgs+=("$(basename "$f")")
    done < <(find "$IMG_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.bmp' \) -print0 2>/dev/null | sort -z)

    if [ ${#imgs[@]} -gt 0 ]; then
        for i in "${!imgs[@]}"; do
            echo -e "    ${DIM}[$((i+1))] ${imgs[$i]}${NC}"
        done
        echo ""
        echo -e "  ${DIM}Escribe el numero para autocompletar o el nombre directo${NC}"
    else
        echo -e "    ${DIM}(sin imagenes)${NC}"
    fi

    echo ""
    read -rp "  Archivo de imagen: " file_input

    # Si es un numero, usar la imagen correspondiente
    local file_name="$file_input"
    if [[ "$file_input" =~ ^[0-9]+$ ]] && [ "$file_input" -ge 1 ] && [ "$file_input" -le ${#imgs[@]} ]; then
        file_name="${imgs[$((file_input-1))]}"
        echo -e "  -> ${BOLD}$file_name${NC}"
    fi

    read -rp "  Nombre del contribuidor: " contrib_name

    if [ -z "$file_name" ] && [ -z "$contrib_name" ]; then
        warn "Datos vacios, cancelando"
        return
    fi

    local tmp
    tmp="$(mktemp)"
    jq --arg k "$key" --arg name "$contrib_name" --arg file "$file_name" '
        if .contributors[$k] then
            .contributors[$k] += [{ file: $file, name: $name }]
        else
            .contributors[$k] = [{ file: $file, name: $name }]
        end
    ' "$INDEX_JSON" > "$tmp"
    cp "$tmp" "$INDEX_JSON"
    rm "$tmp"

    ok "Contribucion agregada a '$key': $contrib_name ($file_name)"
    PENDING_CHANGES+=("Agregado contribuidor: $contrib_name en $key")
}

# --- c) Eliminar entrada ---
contrib_eliminar() {
    echo ""
    info "Selecciona el hallazgo"

    if ! seleccionar_hallazgo; then
        return
    fi

    local key="$_selected_finding"
    mostrar_contribucion "$key"

    if ! jq -e --arg k "$key" '.contributors[$k] // empty' "$INDEX_JSON" &>/dev/null; then
        info "No hay entradas en '$key'"
        return
    fi

    local count
    count="$(jq --arg k "$key" '.contributors[$k] | length' "$INDEX_JSON")"

    read -rp "  Numero de entrada a eliminar (0=cancelar): " sel

    [ "$sel" = "0" ] && return
    if ! [[ "$sel" =~ ^[0-9]+$ ]] || [ "$sel" -lt 1 ] || [ "$sel" -gt "$count" ]; then
        error "Seleccion invalida"
        return
    fi

    local idx=$((sel - 1))
    local cname
    cname="$(jq -r --arg k "$key" --argjson i "$idx" '.contributors[$k][$i].name // "(sin nombre)"' "$INDEX_JSON")"

    read -rp "  Eliminar '$cname' de '$key'? [s/n]: " confirm
    if [ "$confirm" = "s" ] || [ "$confirm" = "S" ]; then
        local tmp
        tmp="$(mktemp)"
        jq --arg k "$key" --argjson i "$idx" '
            .contributors[$k] |= del(.[$i])
        ' "$INDEX_JSON" > "$tmp"

        # Si quedo vacio, eliminar la key
        if jq -e --arg k "$key" '.contributors[$k] | length == 0' "$tmp" &>/dev/null; then
            jq --arg k "$key" 'del(.contributors[$k])' "$tmp" > "${tmp}.2"
            cp "${tmp}.2" "$INDEX_JSON"
            rm "${tmp}.2"
        else
            cp "$tmp" "$INDEX_JSON"
        fi
        rm "$tmp"
        ok "'$cname' eliminado de '$key'"
        PENDING_CHANGES+=("Eliminado contribuidor: $cname de $key")
    fi
}

# --- d) Mover contribucion a otro hallazgo ---
contrib_mover() {
    echo ""
    info "Selecciona el hallazgo ORIGEN"

    if ! seleccionar_hallazgo; then
        return
    fi

    local src_key="$_selected_finding"
    mostrar_contribucion "$src_key"

    if ! jq -e --arg k "$src_key" '.contributors[$k] // empty' "$INDEX_JSON" &>/dev/null; then
        info "No hay entradas en '$src_key'"
        return
    fi

    local count
    count="$(jq --arg k "$src_key" '.contributors[$k] | length' "$INDEX_JSON")"

    read -rp "  Numero de entrada a mover (0=cancelar): " sel

    [ "$sel" = "0" ] && return
    if ! [[ "$sel" =~ ^[0-9]+$ ]] || [ "$sel" -lt 1 ] || [ "$sel" -gt "$count" ]; then
        error "Seleccion invalida"
        return
    fi

    local idx=$((sel - 1))
    local move_name move_file
    move_name="$(jq -r --arg k "$src_key" --argjson i "$idx" '.contributors[$k][$i].name // ""' "$INDEX_JSON")"
    move_file="$(jq -r --arg k "$src_key" --argjson i "$idx" '.contributors[$k][$i].file // ""' "$INDEX_JSON")"

    echo ""
    echo -e "  Moviendo: ${BOLD}$move_name${NC} ($move_file)"
    echo ""
    info "Selecciona el hallazgo DESTINO"

    if ! seleccionar_hallazgo; then
        return
    fi

    local dst_key="$_selected_finding"

    if [ "$src_key" = "$dst_key" ]; then
        warn "Origen y destino son el mismo hallazgo"
        return
    fi

    read -rp "  Mover '$move_name' de '$src_key' a '$dst_key'? [s/n]: " confirm
    if [ "$confirm" = "s" ] || [ "$confirm" = "S" ]; then
        local tmp
        tmp="$(mktemp)"

        # Agregar al destino y eliminar del origen
        jq --arg src "$src_key" --arg dst "$dst_key" --argjson i "$idx" \
           --arg name "$move_name" --arg file "$move_file" '
            # Agregar al destino
            (if .contributors[$dst] then
                .contributors[$dst] += [{ file: $file, name: $name }]
            else
                .contributors[$dst] = [{ file: $file, name: $name }]
            end)
            # Eliminar del origen
            | .contributors[$src] |= del(.[$i])
            # Limpiar si quedo vacio
            | if .contributors[$src] | length == 0 then del(.contributors[$src]) else . end
        ' "$INDEX_JSON" > "$tmp"
        cp "$tmp" "$INDEX_JSON"
        rm "$tmp"

        ok "'$move_name' movido de '$src_key' a '$dst_key'"
        PENDING_CHANGES+=("Movido contribuidor: $move_name de $src_key a $dst_key")
    fi
}

# --- e) Registrar imagenes sin asignar ---
contrib_registrar_sin_asignar() {
    local registered_files
    registered_files="$(jq -r '[.contributors | to_entries[] | select(.value | type == "array") | .value[].file] | .[]' "$INDEX_JSON" 2>/dev/null)"

    local unregistered=()
    while IFS= read -r -d '' f; do
        local bname
        bname="$(basename "$f")"
        if ! echo "$registered_files" | grep -qxF "$bname"; then
            unregistered+=("$bname")
        fi
    done < <(find "$IMG_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.bmp' \) -print0 2>/dev/null | sort -z)

    if [ ${#unregistered[@]} -eq 0 ]; then
        info "Todas las imagenes estan registradas."
        return
    fi

    echo ""
    echo -e "  ${BOLD}Imagenes sin registrar:${NC}"
    for i in "${!unregistered[@]}"; do
        echo -e "  [$((i+1))] ${unregistered[$i]}"
    done
    echo ""
    echo "  [t] Registrar todas de una vez"
    echo "  [0] Volver"
    echo ""
    read -rp "  Seleccion: " sel

    [ "$sel" = "0" ] && return

    local to_register=()
    if [ "$sel" = "t" ] || [ "$sel" = "T" ]; then
        to_register=("${unregistered[@]}")
    elif [[ "$sel" =~ ^[0-9]+$ ]] && [ "$sel" -ge 1 ] && [ "$sel" -le ${#unregistered[@]} ]; then
        to_register=("${unregistered[$((sel-1))]}")
    else
        error "Seleccion invalida"
        return
    fi

    for img_file in "${to_register[@]}"; do
        echo ""
        echo -e "  ${BOLD}${CYAN}Registrando: $img_file${NC}"
        separator

        # Intentar autodetectar hallazgo por nombre de archivo
        local base_no_ext="${img_file%.*}"
        local suggested=""
        if jq -e --arg k "$base_no_ext" '.findings[] | select(.key == $k)' "$INDEX_JSON" &>/dev/null; then
            suggested="$base_no_ext"
            echo -e "  ${GREEN}Hallazgo detectado automaticamente: $suggested${NC}"
            echo ""
            read -rp "  Usar '$suggested'? [s/n]: " use_auto

            if [ "$use_auto" = "s" ] || [ "$use_auto" = "S" ]; then
                _selected_finding="$suggested"
            else
                echo ""
                info "Selecciona el hallazgo manualmente"
                if ! seleccionar_hallazgo; then
                    continue
                fi
            fi
        else
            echo -e "  ${DIM}No se pudo detectar hallazgo por nombre de archivo${NC}"
            echo ""
            info "Selecciona el hallazgo"
            if ! seleccionar_hallazgo; then
                continue
            fi
        fi

        local key="$_selected_finding"

        echo ""
        read -rp "  Nombre del contribuidor: " contrib_name

        local tmp
        tmp="$(mktemp)"
        jq --arg k "$key" --arg name "$contrib_name" --arg file "$img_file" '
            if .contributors[$k] then
                .contributors[$k] += [{ file: $file, name: $name }]
            else
                .contributors[$k] = [{ file: $file, name: $name }]
            end
        ' "$INDEX_JSON" > "$tmp"
        cp "$tmp" "$INDEX_JSON"
        rm "$tmp"

        ok "$img_file registrada en '$key' (contribuidor: ${contrib_name:-(vacio)})"
        PENDING_CHANGES+=("Registrada imagen: $img_file en $key")
    done
}

# ============================================================
# 5. Commitear cambios
# ============================================================
menu_commit() {
    echo ""
    echo -e "${BOLD}  Commitear cambios${NC}"
    separator

    cd "$SCRIPT_DIR"
    local status
    status="$(git status --short 2>/dev/null)"

    if [ -z "$status" ]; then
        info "No hay cambios para commitear."
        pause
        return
    fi

    echo ""
    echo -e "  ${CYAN}Archivos modificados:${NC}"
    echo "$status" | while IFS= read -r line; do
        echo "    $line"
    done

    if [ ${#PENDING_CHANGES[@]} -gt 0 ]; then
        echo ""
        echo -e "  ${MAGENTA}Resumen de esta sesion:${NC}"
        for ch in "${PENDING_CHANGES[@]}"; do
            echo "    - $ch"
        done
    fi

    echo ""
    echo "  [1] Commit automatico (mensaje generado)"
    echo "  [2] Commit con mensaje personalizado"
    echo "  [0] Volver sin commitear"
    echo ""
    read -rp "  Opcion: " choice

    case "$choice" in
        1)
            local msg="Add contributions"
            if [ ${#PENDING_CHANGES[@]} -gt 0 ]; then
                msg="Add contributions:"
                for ch in "${PENDING_CHANGES[@]}"; do
                    msg="$msg
- $ch"
                done
            fi
            git add img/ images/ json/
            git commit -m "$msg"
            ok "Commit creado"
            echo ""
            info "Mensaje:"
            echo "$msg"
            PENDING_CHANGES=()
            ;;
        2)
            echo ""
            read -rp "  Mensaje de commit: " custom_msg
            if [ -z "$custom_msg" ]; then
                warn "Mensaje vacio, cancelando"
                pause
                return
            fi
            git add img/ images/ json/
            git commit -m "$custom_msg"
            ok "Commit creado"
            PENDING_CHANGES=()
            ;;
        0)
            return
            ;;
    esac
    pause
}

# ============================================================
# 5. Push
# ============================================================
menu_push() {
    echo ""
    echo -e "${BOLD}  Push al remoto${NC}"
    separator

    cd "$SCRIPT_DIR"
    local branch
    branch="$(git branch --show-current)"
    echo ""
    echo -e "  Rama actual: ${BOLD}$branch${NC}"

    local ahead
    ahead="$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "?")"
    echo -e "  Commits por subir: ${BOLD}$ahead${NC}"

    if [ "$ahead" = "0" ]; then
        info "Nada que pushear."
        pause
        return
    fi

    echo ""
    read -rp "  Pushear a origin/$branch? [s/n]: " confirm
    if [ "$confirm" = "s" ] || [ "$confirm" = "S" ]; then
        git push origin "$branch"
        ok "Push completado"
    else
        info "Cancelado"
    fi
    pause
}

# ============================================================
# 6. Limpiar add/
# ============================================================
menu_limpiar() {
    ensure_add_dir
    echo ""
    echo -e "${BOLD}  Limpiar carpeta add/${NC}"
    separator

    shopt -s nullglob
    local zips=("$ADD_DIR"/*.zip)
    local all_files=("$ADD_DIR"/*)
    shopt -u nullglob

    if [ ${#all_files[@]} -eq 0 ]; then
        info "add/ ya esta vacia."
        pause
        return
    fi

    echo ""
    echo "  Contenido actual:"
    for f in "${all_files[@]}"; do
        local size
        size="$(du -h "$f" | cut -f1)"
        echo "    - $(basename "$f") ($size)"
    done

    echo ""
    echo "  [1] Eliminar todos los ZIPs"
    echo "  [2] Eliminar todo el contenido de add/"
    echo "  [3] Eliminar un archivo especifico"
    echo "  [0] Volver"
    echo ""
    read -rp "  Opcion: " choice

    case "$choice" in
        1)
            if [ ${#zips[@]} -eq 0 ]; then
                info "No hay ZIPs."
            else
                echo ""
                read -rp "  Eliminar ${#zips[@]} ZIP(s)? [s/n]: " confirm
                if [ "$confirm" = "s" ] || [ "$confirm" = "S" ]; then
                    rm -f "${zips[@]}"
                    ok "ZIPs eliminados"
                fi
            fi
            ;;
        2)
            echo ""
            read -rp "  Eliminar TODO en add/? [s/n]: " confirm
            if [ "$confirm" = "s" ] || [ "$confirm" = "S" ]; then
                rm -rf "${all_files[@]}"
                ok "add/ limpiada"
            fi
            ;;
        3)
            echo ""
            for i in "${!all_files[@]}"; do
                echo "  [$((i+1))] $(basename "${all_files[$i]}")"
            done
            echo ""
            read -rp "  Numero de archivo a eliminar: " fsel
            if [[ "$fsel" =~ ^[0-9]+$ ]] && [ "$fsel" -ge 1 ] && [ "$fsel" -le ${#all_files[@]} ]; then
                local target="${all_files[$((fsel-1))]}"
                read -rp "  Eliminar $(basename "$target")? [s/n]: " confirm
                if [ "$confirm" = "s" ] || [ "$confirm" = "S" ]; then
                    rm -rf "$target"
                    ok "Eliminado"
                fi
            else
                error "Seleccion invalida"
            fi
            ;;
        0) return ;;
    esac
    pause
}

# ============================================================
# 7. Verificar dependencias
# ============================================================
menu_verificar() {
    echo ""
    echo -e "${BOLD}  Verificacion del sistema${NC}"
    separator
    echo ""

    # jq
    if command -v jq &>/dev/null; then
        ok "jq instalado ($(jq --version))"
    else
        error "jq NO instalado - merge de JSON no funcionara"
        echo "      Instalar: sudo pacman -S jq"
    fi

    # unzip
    if command -v unzip &>/dev/null; then
        ok "unzip instalado"
    else
        error "unzip NO instalado - no se pueden leer ZIPs"
    fi

    # git
    if command -v git &>/dev/null; then
        ok "git instalado ($(git --version | cut -d' ' -f3))"
    else
        error "git NO instalado"
    fi

    # Estructura de directorios
    echo ""
    info "Estructura de directorios:"
    for dir in "$IMG_DIR" "$EQUIP_IMG_DIR" "$JSON_DIR" "$ADD_DIR"; do
        local rel="${dir#$SCRIPT_DIR/}"
        if [ -d "$dir" ]; then
            ok "$rel/"
        else
            warn "$rel/ no existe"
        fi
    done

    # Archivos clave
    echo ""
    info "Archivos clave:"
    for f in "$EQUIP_JSON" "$INDEX_JSON"; do
        local rel="${f#$SCRIPT_DIR/}"
        if [ -f "$f" ]; then
            ok "$rel"
        else
            warn "$rel no encontrado"
        fi
    done

    pause
}

# ============================================================
# 8. Log de git reciente
# ============================================================
menu_log() {
    echo ""
    echo -e "${BOLD}  Historial de commits recientes${NC}"
    separator
    echo ""
    cd "$SCRIPT_DIR"
    git log --oneline --graph -15
    pause
}

# ============================================================
# Menu principal
# ============================================================
main_menu() {
    while true; do
        clear
        echo ""
        echo -e "${BOLD}${CYAN}  OtoReports - Gestor de Contribuciones${NC}"
        echo -e "${DIM}  $(date '+%Y-%m-%d %H:%M')${NC}"
        separator

        # Indicador de cambios pendientes
        if [ ${#PENDING_CHANGES[@]} -gt 0 ]; then
            echo -e "  ${MAGENTA}${BOLD}* ${#PENDING_CHANGES[@]} cambio(s) sin commitear${NC}"
            separator
        fi

        echo ""
        echo -e "  ${BOLD}1)${NC} Listar ZIPs en add/"
        echo -e "  ${BOLD}2)${NC} Ver estado actual del sistema"
        echo -e "  ${BOLD}3)${NC} Instalar contribucion"
        echo -e "  ${BOLD}4)${NC} Editar contribuciones existentes"
        echo -e "  ${BOLD}5)${NC} Commitear cambios"
        echo -e "  ${BOLD}6)${NC} Push al remoto"
        echo -e "  ${BOLD}7)${NC} Limpiar add/"
        echo -e "  ${BOLD}8)${NC} Verificar dependencias"
        echo -e "  ${BOLD}9)${NC} Historial de commits"
        echo ""
        echo -e "  ${BOLD}0)${NC} Salir"
        echo ""
        read -rp "  > " opt

        case "$opt" in
            1) menu_listar_zips ;;
            2) menu_estado_actual ;;
            3) menu_instalar ;;
            4) menu_editar ;;
            5) menu_commit ;;
            6) menu_push ;;
            7) menu_limpiar ;;
            8) menu_verificar ;;
            9) menu_log ;;
            0|q|Q)
                if [ ${#PENDING_CHANGES[@]} -gt 0 ]; then
                    echo ""
                    warn "Tienes ${#PENDING_CHANGES[@]} cambio(s) sin commitear!"
                    read -rp "  Salir de todas formas? [s/n]: " confirm
                    if [ "$confirm" != "s" ] && [ "$confirm" != "S" ]; then
                        continue
                    fi
                fi
                echo ""
                info "Hasta luego."
                echo ""
                exit 0
                ;;
            *)
                warn "Opcion no valida"
                sleep 1
                ;;
        esac
    done
}

# --- Entrada ---
ensure_add_dir
main_menu
