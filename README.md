# Otoreports Findings

Repositorio de imágenes clínicas y datos de hallazgos otoscópicos para [OtoReport](https://github.com/TecMedHub/OtoReport).

## Estructura

```
Otoreports_findings/
├── img/              # Imágenes clínicas de hallazgos (.webp)
├── json/             # Metadatos, marcas y símbolos por hallazgo
└── README.md
```

## Imágenes (`img/`)

Cada hallazgo se identifica por su **key** (ej: `perforation_central`, `cae_cerumen_impacted`).

### Convención de nombres

| Archivo | Descripción |
|---------|-------------|
| `{key}.webp` | Imagen principal del hallazgo |
| `{key}_2.webp` | Segunda imagen (variante) |
| `{key}_3.webp` | Tercera imagen, etc. |

### Requisitos de imagen

- **Formato**: WebP (preferido por tamaño y calidad)
- **Resolución**: mínimo 400x300px, máximo 1200x900px
- **Relación de aspecto**: 4:3 (recomendado)
- **Tamaño**: < 200 KB por imagen
- **Contenido**: Imagen otoscópica clínica representativa del hallazgo
- **Sin datos personales**: Las imágenes NO deben contener datos identificables del paciente

### Cómo agregar una imagen

1. Obtener una imagen otoscópica representativa del hallazgo
2. Recortar al área de interés (membrana timpánica o conducto auditivo)
3. Convertir a WebP:
   ```bash
   # Con ImageMagick
   convert input.jpg -resize 800x600 -quality 80 img/{key}.webp

   # Con cwebp (libwebp)
   cwebp -q 80 -resize 800 600 input.jpg -o img/{key}.webp

   # Con ffmpeg
   ffmpeg -i input.jpg -vf scale=800:600 -quality 80 img/{key}.webp
   ```
4. Verificar que el nombre coincida exactamente con el `key` del hallazgo
5. **Registrar tu nombre** en `json/index.json` dentro del campo `contributors`:
   ```json
   {
     "contributors": {
       "perforation_central": [
         { "file": "perforation_central.webp", "name": "Dr. Juan Pérez" }
       ],
       "cae_cerumen_impacted": [
         { "file": "cae_cerumen_impacted.webp", "name": "Dra. María López" },
         { "file": "cae_cerumen_impacted_2.webp", "name": "Dr. Carlos Soto" }
       ]
     }
   }
   ```
   > **Formato**: Cada key mapea a un array de objetos `{ file, name }`. Si un hallazgo tiene múltiples imágenes de distintos colaboradores, se agregan como entradas adicionales al array. El formato legacy (string) sigue siendo soportado pero se recomienda migrar al nuevo formato.
6. **Alternativa: Paquete desde OtoReport** — En la Biblioteca de Hallazgos de OtoReport, selecciona "Contribuir" en cualquier tarjeta para generar un paquete `.zip` con la imagen anotada y metadatos. Envíalo al equipo de TecMedHub por Instagram o GitHub.
7. Commit y push

> **Importante**: Tu nombre aparecerá en la Biblioteca de Hallazgos de OtoReport como crédito por tu contribución.

## JSON de marcas y símbolos (`json/`)

Cada archivo JSON define las marcas y símbolos asociados a un hallazgo para el diagrama timpánico.

### Formato

```json
{
  "key": "perforation_central",
  "symbols": [
    {
      "id": "perf_outline",
      "type": "circle",
      "x": 0.5,
      "y": 0.5,
      "radius": 0.15,
      "stroke": "#e53e3e",
      "fill": "rgba(229, 62, 62, 0.2)"
    }
  ]
}
```

Las coordenadas son **normalizadas (0-1)** relativas al diagrama timpánico.

## Lista completa de hallazgos

### Membrana Timpánica

| Key | ES | EN |
|-----|----|----|
| `normal` | Normal | Normal |
| `retraction` | Retracción | Retraction |
| `retraction_grade_i` | Retracción grado I | Retraction grade I |
| `retraction_grade_ii` | Retracción grado II | Retraction grade II |
| `retraction_grade_iii` | Retracción grado III | Retraction grade III |
| `retraction_grade_iv` | Retracción grado IV | Retraction grade IV |
| `retraction_as` | Retracción anterosuperior | Anterosuperior retraction |
| `retraction_ai` | Retracción anteroinferior | Anteroinferior retraction |
| `retraction_ps` | Retracción posterosuperior | Posterosuperior retraction |
| `retraction_pi` | Retracción posteroinferior | Posteroinferior retraction |
| `retraction_pars_flaccida` | Retracción pars flácida | Pars flaccida retraction |
| `retraction_pars_tensa` | Retracción pars tensa | Pars tensa retraction |
| `atelectasis` | Atelectasia | Atelectasis |
| `perforation` | Perforación | Perforation |
| `perforation_central` | Perforación central | Central perforation |
| `perforation_marginal` | Perforación marginal | Marginal perforation |
| `perforation_subtotal` | Perforación subtotal | Subtotal perforation |
| `perforation_total` | Perforación total | Total perforation |
| `perforation_anterior` | Perforación anterior | Anterior perforation |
| `perforation_posterior` | Perforación posterior | Posterior perforation |
| `perforation_inferior` | Perforación inferior | Inferior perforation |
| `perforation_attic` | Perforación ático | Attic perforation |
| `perforation_kidney` | Perforación reniforme | Kidney-shaped perforation |
| `perforation_dry` | Perforación seca | Dry perforation |
| `perforation_wet` | Perforación húmeda | Wet perforation |
| `perforation_healed` | Perforación cicatrizada | Healed perforation |
| `effusion` | Efusión | Effusion |
| `effusion_serous` | Efusión serosa | Serous effusion |
| `effusion_mucoid` | Efusión mucoide | Mucoid effusion |
| `effusion_purulent` | Efusión purulenta | Purulent effusion |
| `air_fluid_level` | Nivel hidroaéreo | Air-fluid level |
| `air_bubbles` | Burbujas de aire | Air bubbles |
| `hemotympanum` | Hemotímpano | Hemotympanum |
| `blue_ear` | Oído azul | Blue ear |
| `tympanosclerosis` | Timpanoesclerosis | Tympanosclerosis |
| `tympanosclerosis_focal` | Timpanoesclerosis focal | Focal tympanosclerosis |
| `tympanosclerosis_diffuse` | Timpanoesclerosis difusa | Diffuse tympanosclerosis |
| `calcification` | Calcificación | Calcification |
| `inflammation` | Inflamación | Inflammation |
| `hyperemia` | Hiperemia | Hyperemia |
| `edema_membrane` | Edema de membrana | Membrane edema |
| `oma_acute` | OMA aguda | Acute otitis media |
| `oma_recurrent` | OMA recurrente | Recurrent AOM |
| `omc_simple` | OMC simple | Simple COM |
| `omc_suppurative` | OMC supurada | Suppurative COM |
| `ome` | OME | OME |
| `bulging` | Abombamiento | Bulging |
| `bulging_focal` | Abombamiento focal | Focal bulging |
| `bulging_diffuse` | Abombamiento difuso | Diffuse bulging |
| `cholesteatoma` | Colesteatoma | Cholesteatoma |
| `cholesteatoma_attic` | Colesteatoma ático | Attic cholesteatoma |
| `cholesteatoma_sinus` | Colesteatoma seno | Sinus cholesteatoma |
| `cholesteatoma_congenital` | Colesteatoma congénito | Congenital cholesteatoma |
| `keratin_debris` | Restos queratínicos | Keratin debris |
| `pearl` | Perla de queratina | Keratin pearl |
| `tube` | Tubo de ventilación | Ventilation tube |
| `tube_patent` | Tubo permeable | Patent tube |
| `tube_blocked` | Tubo obstruido | Blocked tube |
| `tube_extruding` | Tubo en extrusión | Extruding tube |
| `tube_medial` | Tubo medializado | Medialized tube |
| `myringitis` | Miringitis | Myringitis |
| `myringitis_bullosa` | Miringitis bullosa | Bullous myringitis |
| `myringitis_granulosa` | Miringitis granulosa | Granular myringitis |
| `granulation` | Tejido de granulación | Granulation tissue |
| `polyp` | Pólipo | Polyp |
| `granuloma` | Granuloma | Granuloma |
| `tumor_middle_ear` | Tumor oído medio | Middle ear tumor |
| `glomus_tympanicum` | Glomus timpánico | Glomus tympanicum |
| `neomembrane` | Neomembrana | Neomembrane |
| `scarring` | Cicatriz | Scarring |
| `dimeric_membrane` | Membrana dimérica | Dimeric membrane |
| `monomeric_membrane` | Membrana monomérica | Monomeric membrane |
| `myringoplasty` | Miringoplastía | Myringoplasty |
| `tympanoplasty` | Timpanoplastía | Tympanoplasty |
| `cerumen` | Cerumen sobre MT | Cerumen on TM |
| `foreign_body` | Cuerpo extraño sobre MT | Foreign body on TM |
| `opaque` | Opacidad | Opacity |
| `loss_light_reflex` | Pérdida de cono luminoso | Loss of light reflex |
| `vascular_injection` | Inyección vascular | Vascular injection |
| `neovascularization` | Neovascularización | Neovascularization |
| `ossicular_erosion` | Erosión osicular | Ossicular erosion |
| `ossicular_fixation` | Fijación osicular | Ossicular fixation |
| `stapes_visible` | Estribo visible | Stapes visible |
| `promontory_visible` | Promontorio visible | Promontory visible |
| `round_window_visible` | Ventana redonda visible | Round window visible |
| `incus_necrosis` | Necrosis de yunque | Incus necrosis |
| `malleus_prominent` | Mango del martillo prominente | Prominent malleus handle |
| `malleus_lateral` | Martillo lateralizado | Lateralized malleus |
| `retraction_pocket` | Bolsillo de retracción | Retraction pocket |
| `adhesive_otitis` | Otitis adhesiva | Adhesive otitis |
| `traumatic_rupture` | Ruptura traumática | Traumatic rupture |

### Conducto Auditivo Externo (CAE)

| Key | ES | EN |
|-----|----|----|
| `cae_normal` | Normal | Normal |
| `cae_cerumen` | Cerumen | Cerumen |
| `cae_cerumen_partial` | Cerumen parcial | Partial cerumen |
| `cae_cerumen_impacted` | Tapón de cerumen | Impacted cerumen |
| `cae_cerumen_wet` | Cerumen húmedo | Wet cerumen |
| `cae_cerumen_dry` | Cerumen seco | Dry cerumen |
| `cae_edema` | Edema | Edema |
| `cae_otitis_externa_diffuse` | Otitis externa difusa | Diffuse otitis externa |
| `cae_otitis_externa_necrotizing` | Otitis externa necrotizante | Necrotizing otitis externa |
| `cae_furuncle` | Forúnculo | Furuncle |
| `cae_cellulitis` | Celulitis | Cellulitis |
| `cae_erythema` | Eritema | Erythema |
| `cae_otorrhea` | Otorrea | Otorrhea |
| `cae_otorrhea_serous` | Otorrea serosa | Serous otorrhea |
| `cae_otorrhea_mucoid` | Otorrea mucoide | Mucoid otorrhea |
| `cae_otorrhea_purulent` | Otorrea purulenta | Purulent otorrhea |
| `cae_otorrhea_bloody` | Otorragia | Otorrhagia |
| `cae_otorrhea_fetid` | Otorrea fétida | Fetid otorrhea |
| `cae_exostosis` | Exostosis | Exostosis |
| `cae_osteoma` | Osteoma | Osteoma |
| `cae_eczema` | Eccema | Eczema |
| `cae_dermatitis` | Dermatitis | Dermatitis |
| `cae_psoriasis` | Psoriasis | Psoriasis |
| `cae_seborrheic` | Dermatitis seborreica | Seborrheic dermatitis |
| `cae_keratosis` | Queratosis | Keratosis |
| `cae_otomycosis` | Otomicosis | Otomycosis |
| `cae_otomycosis_aspergillus` | Otomicosis (Aspergillus) | Otomycosis (Aspergillus) |
| `cae_otomycosis_candida` | Otomicosis (Candida) | Otomycosis (Candida) |
| `cae_foreign_body` | Cuerpo extraño | Foreign body |
| `cae_insect` | Insecto | Insect |
| `cae_stenosis` | Estenosis | Stenosis |
| `cae_stenosis_acquired` | Estenosis adquirida | Acquired stenosis |
| `cae_atresia` | Atresia | Atresia |
| `cae_collapse` | Colapso | Collapse |
| `cae_bleeding` | Sangrado | Bleeding |
| `cae_granulation` | Granulación | Granulation |
| `cae_tumor` | Tumor del conducto | Canal tumor |
| `cae_carcinoma` | Carcinoma | Carcinoma |
| `cae_mastoid_cavity` | Cavidad mastoidea | Mastoid cavity |
| `cae_meatoplasty` | Meatoplastía | Meatoplasty |
| `cae_herpes_zoster` | Vesículas herpéticas (Herpes Zóster) | Herpetic vesicles (Herpes Zoster) |
| `cae_hyperemia` | Hiperemia del CAE | EAC hyperemia |
| `cae_microtia_i` | Microtia grado I | Microtia grade I |
| `cae_microtia_ii` | Microtia grado II | Microtia grade II |
| `cae_microtia_iii` | Microtia grado III | Microtia grade III |
| `cae_microtia_iv` | Microtia grado IV (Anotia) | Microtia grade IV (Anotia) |
| `cae_agenesis_a` | Agenesia tipo A (Estenosis) | Agenesis type A (Stenosis) |
| `cae_agenesis_b` | Agenesia tipo B (Estenosis medial) | Agenesis type B (Medial stenosis) |
| `cae_agenesis_c` | Agenesia tipo C (Atresia ósea) | Agenesis type C (Bony atresia) |

## Cómo contribuir

1. Fork del repositorio
2. Agrega las imágenes en `img/` siguiendo la convención de nombres
3. (Opcional) Agrega los símbolos en `json/` si el hallazgo tiene marcas para el diagrama
4. Crea un Pull Request describiendo qué hallazgos se agregaron

## Licencia

Las imágenes clínicas deben ser de uso libre o contar con consentimiento explícito para su publicación. No se aceptan imágenes con datos identificables de pacientes.
