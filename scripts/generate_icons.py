#!/usr/bin/env python3
"""
Generate multi-size icon assets (SVGs and PNGs at @1x and @2x)
across all supported build-time variants for Jots.
"""

import os
import sys

# Variants configuration
VARIANTS = {
    'default': {
        'paper_start': '#FFDD53',
        'paper_mid': '#FCD232',
        'paper_end': '#F5BD19',
        'fold_start': '#FFF5B8',
        'fold_mid': '#FEEA85',
        'fold_end': '#E5BE30',
        'ink_primary': '#0E3D9E',
        'ink_dark': '#0B3082',
        'ink_accent': '#072260',
        'hazard_bottom': False,
        'accent_type': 'underlines',
    },
    'devel': {
        'paper_start': '#FFF5C0',
        'paper_mid': '#FEECA8',
        'paper_end': '#F9DF88',
        'fold_start': '#FFFFFF',
        'fold_mid': '#FFF8DE',
        'fold_end': '#F2D372',
        'ink_primary': '#0E3D9E',
        'ink_dark': '#0B3082',
        'ink_accent': '#072260',
        'hazard_bottom': True,
        'accent_type': 'code_brackets',
    },
    'halloween': {
        'paper_start': '#FFA033',
        'paper_mid': '#FF841A',
        'paper_end': '#E65C00',
        'fold_start': '#FFD199',
        'fold_mid': '#FFBA66',
        'fold_end': '#CC5200',
        'ink_primary': '#2B2438',
        'ink_dark': '#1C1626',
        'ink_accent': '#120D1A',
        'hazard_bottom': False,
        'accent_type': 'spooky_ghost_boo', # spooky ghost + playful hand-drawn 'BOO!' callout
    },
    'pride': {
        'paper_start': '#FFFBF0',
        'paper_mid': '#FFF4D6',
        'paper_end': '#F7E7BE',
        'fold_start': '#FFFFFF',
        'fold_mid': '#FFFDF8',
        'fold_end': '#EFE0B6',
        'ink_primary': '#0E3D9E',
        'ink_dark': '#0B3082',
        'ink_accent': '#072260',
        'hazard_bottom': False,
        'accent_type': 'three_line_rainbow',
    },
    'classic': {
        'paper_start': '#F6E6C2',
        'paper_mid': '#EEDB9F',
        'paper_end': '#DFC67F',
        'fold_start': '#FFF8E6',
        'fold_mid': '#F8E8C0',
        'fold_end': '#CEB060',
        'ink_primary': '#3E342B',
        'ink_dark': '#29221C',
        'ink_accent': '#1B1612',
        'hazard_bottom': False,
        'accent_type': 'underlines',
    },
}

SIZES = [16, 24, 32, 48, 64, 128]


def get_accent_svg(accent_type, ink_dark, ink_accent, paper_color, size_tier):
    """Generate SVG markup for the bottom accent based on theme and icon size tier."""
    if accent_type == 'underlines':
        if size_tier == 'small':
            return f'''
    <path d="M 230 420 L 360 405 M 238 444 L 368 428"
          fill="none" stroke="{ink_dark}" stroke-width="26" stroke-linecap="round" />
            '''
        else:
            return f'''
    <path d="M 230 418 C 268 409 314 402 362 398"
          fill="none" stroke="{ink_dark}" stroke-width="7" stroke-linecap="round" />
    <path d="M 233 419 C 270 410 316 403 358 399"
          fill="none" stroke="{ink_accent}" stroke-width="3" stroke-linecap="round" opacity="0.75" />
    <path d="M 238 440 C 276 433 322 426 372 422"
          fill="none" stroke="{ink_dark}" stroke-width="7" stroke-linecap="round" />
    <path d="M 241 441 C 278 434 324 427 368 423"
          fill="none" stroke="{ink_accent}" stroke-width="3" stroke-linecap="round" opacity="0.75" />
            '''

    elif accent_type == 'code_brackets':
        if size_tier == 'small':
            return f'''
    <!-- Hand-drawn uneven code brackets </ > for small sizes -->
    <path d="M 262 384 C 250 392 242 398 238 400 C 246 405 256 410 263 414 M 274 416 C 282 398 288 388 293 380 M 308 383 C 318 390 326 397 331 401 C 324 407 316 412 309 415"
          fill="none" stroke="{ink_dark}" stroke-width="16" stroke-linecap="round" stroke-linejoin="round" />
            '''
        else:
            return f'''
    <!-- Organic, hand-drawn uneven developer code brackets </ > -->
    <path d="
      M 266 378
      C 254 388 243 394 236 398
      C 244 404 256 410 265 418"
      fill="none" stroke="{ink_dark}" stroke-width="6.5" stroke-linecap="round" stroke-linejoin="round" />
    <path d="
      M 268 379
      C 256 389 246 394 238 398
      C 246 404 258 410 267 417"
      fill="none" stroke="{ink_accent}" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" opacity="0.75" />

    <path d="
      M 278 421
      C 285 406 291 391 299 375"
      fill="none" stroke="{ink_dark}" stroke-width="6.5" stroke-linecap="round" />
    <path d="
      M 280 420
      C 287 405 292 392 300 376"
      fill="none" stroke="{ink_accent}" stroke-width="2.5" stroke-linecap="round" opacity="0.75" />

    <path d="
      M 312 381
      C 324 389 334 397 341 401
      C 333 407 321 413 311 416"
      fill="none" stroke="{ink_dark}" stroke-width="6.5" stroke-linecap="round" stroke-linejoin="round" />
    <path d="
      M 310 382
      C 322 390 331 397 338 401
      C 331 407 320 412 309 415"
      fill="none" stroke="{ink_accent}" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" opacity="0.75" />
            '''

    elif accent_type == 'three_line_rainbow':
        if size_tier == 'small':
            return f'''
    <!-- Tilted 3-line rainbow arch (Small sizes, pixel-fitted) -->
    <path d="M 216 450 C 248 375 330 380 375 432"
          fill="none" stroke="{ink_dark}" stroke-width="18" stroke-linecap="round" />
    <path d="M 230 456 C 258 392 324 396 360 440"
          fill="none" stroke="{ink_dark}" stroke-width="18" stroke-linecap="round" />
    <path d="M 244 462 C 266 408 316 412 344 448"
          fill="none" stroke="{ink_dark}" stroke-width="18" stroke-linecap="round" />
            '''
        else:
            return f'''
    <!-- Tilted & deeply curved hand-drawn 3-line rainbow arch (Pride variant) -->
    <path d="
      M 212 452
      C 246 368 334 374 382 430"
      fill="none" stroke="{ink_dark}" stroke-width="6.5" stroke-linecap="round" />
    <path d="
      M 214 453
      C 248 370 332 376 379 431"
      fill="none" stroke="{ink_accent}" stroke-width="2.5" stroke-linecap="round" opacity="0.75" />

    <path d="
      M 226 459
      C 256 386 326 392 366 440"
      fill="none" stroke="{ink_dark}" stroke-width="6.5" stroke-linecap="round" />
    <path d="
      M 228 460
      C 258 388 324 394 363 441"
      fill="none" stroke="{ink_accent}" stroke-width="2.5" stroke-linecap="round" opacity="0.75" />

    <path d="
      M 240 466
      C 264 402 318 408 350 450"
      fill="none" stroke="{ink_dark}" stroke-width="6.5" stroke-linecap="round" />
    <path d="
      M 242 467
      C 266 404 316 410 347 451"
      fill="none" stroke="{ink_accent}" stroke-width="2.5" stroke-linecap="round" opacity="0.75" />
            '''

    elif accent_type == 'spooky_ghost_boo':
        if size_tier == 'small':
            return f'''
    <!-- Solid Silhouette Spooky Ghost completely within note canvas for low-res -->
    <path d="
      M 312 350
      C 290 350 274 370 272 396
      C 256 396 242 402 240 415
      C 240 425 248 431 254 426
      C 259 434 267 432 272 426
      C 266 440 256 452 254 458
      C 270 450 284 448 296 456
      C 308 464 320 464 330 456
      C 342 448 356 450 368 458
      C 364 452 354 440 348 426
      C 353 432 361 434 366 426
      C 372 431 380 425 380 415
      C 378 402 364 396 348 396
      C 346 370 330 350 312 350 Z"
      fill="{ink_dark}" />
    <!-- Cut-out oval eyes & gasp mouth showing paper color -->
    <ellipse cx="298" cy="380" rx="4" ry="6" fill="{paper_color}" />
    <ellipse cx="326" cy="380" rx="4" ry="6" fill="{paper_color}" />
    <ellipse cx="312" cy="404" rx="4.5" ry="7" fill="{paper_color}" />
            '''
        else:
            return f'''
    <!-- Playful Hand-Drawn 'BOO!' Speech Callout -->
    <!-- Speech bubble cloud -->
    <path d="
      M 160 415
      C 150 405 160 390 174 392
      C 182 382 202 382 212 390
      C 224 388 236 398 234 412
      C 244 422 238 436 226 440
      C 220 448 202 448 194 442
      C 188 448 172 448 166 440
      C 152 438 148 424 160 415 Z"
      fill="{paper_color}" stroke="{ink_dark}" stroke-width="4.5" stroke-linecap="round" stroke-linejoin="round" />
    <path d="M 230 435 L 250 430" stroke="{ink_dark}" stroke-width="4" stroke-linecap="round" />

    <!-- Hand-lettered BOO! text -->
    <!-- B -->
    <path d="M 172 408 L 172 432 M 172 408 C 180 406 186 412 182 418 C 188 418 188 430 172 430"
          fill="none" stroke="{ink_dark}" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round" />
    <!-- O -->
    <ellipse cx="194" cy="420" rx="4" ry="6" fill="none" stroke="{ink_dark}" stroke-width="3.5" />
    <!-- O -->
    <ellipse cx="206" cy="420" rx="4" ry="6" fill="none" stroke="{ink_dark}" stroke-width="3.5" />
    <!-- ! -->
    <line x1="218" y1="412" x2="218" y2="425" stroke="{ink_dark}" stroke-width="3.5" stroke-linecap="round" />
    <circle cx="218" cy="430" r="1.8" fill="{ink_dark}" />

    <!-- Classic Spooky Ghost Hand-Drawn Outline -->
    <path d="
      M 312 348
      C 288 348 272 368 270 395
      C 254 395 240 401 238 415
      C 238 425 246 431 253 426
      C 258 434 266 433 271 426
      C 265 441 254 454 252 460
      C 268 452 282 450 295 458
      C 307 466 320 466 330 458
      C 343 450 357 452 371 460
      C 368 454 358 441 352 426
      C 357 433 365 434 370 426
      C 377 431 385 425 385 415
      C 383 401 369 395 353 395
      C 351 368 335 348 312 348 Z"
      fill="none" stroke="{ink_dark}" stroke-width="6.5" stroke-linecap="round" stroke-linejoin="round" />

    <!-- Pen Over-Trace Accent Line -->
    <path d="
      M 312 349
      C 289 349 273 369 271 396
      C 255 396 241 402 239 415
      C 239 424 247 430 253 426
      C 258 433 265 432 270 426
      C 264 441 254 453 252 459
      C 268 451 282 449 295 457
      C 307 465 320 465 330 457
      C 343 449 357 451 370 459
      C 367 453 358 441 352 426
      C 356 432 364 433 369 426
      C 375 430 383 424 383 415
      C 381 402 368 396 352 396
      C 350 369 334 349 312 349 Z"
      fill="none" stroke="{ink_accent}" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" opacity="0.75" />

    <!-- Classic Oval Eyes & Open Gasp Mouth -->
    <ellipse cx="298" cy="380" rx="4.5" ry="7.5" fill="{ink_dark}" />
    <ellipse cx="326" cy="380" rx="4.5" ry="7.5" fill="{ink_dark}" />
    <ellipse cx="312" cy="406" rx="5.5" ry="9" fill="{ink_dark}" />
            '''

    return ''


def get_hazard_bottom_svg(size_tier):
    """Integrated black/yellow hazard diagonal stripe footer cleanly chopped and clipped strictly to the bottom tape band."""
    if size_tier == 'small':
        return '''
    <g clip-path="url(#hazard-band-clip-small)">
      <rect x="32" y="440" width="448" height="40" fill="#FEE135" />
      <path d="
        M 10 490 L 70 430 M 60 490 L 120 430 M 110 490 L 170 430
        M 160 490 L 220 430 M 210 490 L 270 430 M 260 490 L 320 430
        M 310 490 L 370 430 M 360 490 L 420 430 M 410 490 L 470 430
        M 460 490 L 520 430"
        stroke="#23272E" stroke-width="24" stroke-linecap="square" />
      <line x1="32" y1="440" x2="480" y2="440" stroke="#23272E" stroke-width="4" />
    </g>
        '''
    else:
        return '''
    <g clip-path="url(#hazard-band-clip-large)">
      <rect x="40" y="432" width="432" height="40" fill="#FEE135" />
      <path d="
        M 15 482 L 75 422 M 65 482 L 125 422 M 115 482 L 175 422
        M 165 482 L 225 422 M 215 482 L 275 422 M 265 482 L 325 422
        M 315 482 L 375 422 M 365 482 L 425 422 M 415 482 L 475 422
        M 465 482 L 525 422"
        stroke="#23272E" stroke-width="18" stroke-linecap="square" />
      <line x1="40" y1="432" x2="472" y2="432" stroke="#23272E" stroke-width="4" />
    </g>
        '''


def generate_svg_markup(variant_name, size_tier='large'):
    """Generate SVG vector XML string for a specific variant and size tier."""
    cfg = VARIANTS[variant_name]
    hazard_footer = get_hazard_bottom_svg(size_tier) if cfg['hazard_bottom'] else ''
    accent = get_accent_svg(cfg['accent_type'], cfg['ink_dark'], cfg['ink_accent'], cfg['paper_start'], size_tier)

    # 1. Size Tier: Small (16px, 24px)
    if size_tier == 'small':
        return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <defs>
    <linearGradient id="note-grad" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="{cfg['paper_start']}" />
      <stop offset="100%" stop-color="{cfg['paper_end']}" />
    </linearGradient>
    <linearGradient id="fold-grad" x1="0%" y1="100%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="{cfg['fold_start']}" />
      <stop offset="100%" stop-color="{cfg['fold_end']}" />
    </linearGradient>
    <clipPath id="note-outline-clip">
      <path d="M 96 32 L 352 32 L 480 160 L 480 416 C 480 452 452 480 416 480 L 96 480 C 60 480 32 452 32 416 L 32 96 C 32 60 60 32 96 32 Z" />
    </clipPath>
    <clipPath id="hazard-band-clip-small">
      <path d="M 32 440 L 480 440 L 480 416 C 480 452 452 480 416 480 L 96 480 C 60 480 32 452 32 416 Z" />
    </clipPath>
  </defs>

  <!-- Sticky Note Body -->
  <path d="M 96 32 L 352 32 L 480 160 L 480 416 C 480 452 452 480 416 480 L 96 480 C 60 480 32 452 32 416 L 32 96 C 32 60 60 32 96 32 Z"
        fill="url(#note-grad)" />

  {hazard_footer}

  <!-- Dog-Ear Corner -->
  <path d="M 352 32 C 352 96 384 160 480 160 Z"
        fill="url(#fold-grad)" />

  <!-- Solid Bold J Glyph -->
  <path d="
    M 175 142
    C 210 134 260 126 325 120
    C 334 119 340 126 336 135
    C 330 148 314 156 295 158
    C 292 195 285 260 270 318
    C 255 372 225 398 178 398
    C 134 398 112 362 114 322
    C 116 288 140 270 162 272
    C 180 274 188 290 184 308
    C 178 334 162 346 154 348
    C 160 360 172 368 192 366
    C 220 362 242 334 250 285
    C 260 225 264 170 265 146
    C 230 152 194 162 174 170
    C 165 174 158 164 164 154
    C 167 148 171 144 175 142 Z"
    fill="{cfg['ink_primary']}" stroke="{cfg['ink_dark']}" stroke-width="8" stroke-linejoin="round" />

  {accent}
</svg>'''

    # 2. Size Tier: Medium (32px, 48px)
    elif size_tier == 'medium':
        return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <defs>
    <filter id="note-shadow" x="-8%" y="-8%" width="120%" height="124%">
      <feDropShadow dx="0" dy="14" stdDeviation="12" flood-color="#141005" flood-opacity="0.16" />
    </filter>
    <filter id="dogear-shadow" x="-20%" y="-20%" width="150%" height="150%">
      <feDropShadow dx="-4" dy="8" stdDeviation="6" flood-color="#3A2800" flood-opacity="0.20" />
    </filter>
    <linearGradient id="note-grad" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="{cfg['paper_start']}" />
      <stop offset="100%" stop-color="{cfg['paper_end']}" />
    </linearGradient>
    <linearGradient id="fold-grad" x1="0%" y1="100%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="{cfg['fold_start']}" />
      <stop offset="100%" stop-color="{cfg['fold_end']}" />
    </linearGradient>
    <clipPath id="note-outline-clip">
      <path d="M 112 40 L 352 40 Q 360 40 366 46 L 466 146 Q 472 152 472 160 L 472 400 C 472 440 440 472 400 472 L 112 472 C 72 472 40 440 40 400 L 40 112 C 40 72 72 40 112 40 Z" />
    </clipPath>
    <clipPath id="hazard-band-clip-large">
      <path d="M 40 432 L 472 432 L 472 400 C 472 440 440 472 400 472 L 112 472 C 72 472 40 440 40 400 Z" />
    </clipPath>
    <clipPath id="j-clip">
      <path d="
        M 175 142 C 210 134 260 126 325 120 C 334 119 340 126 336 135
        C 330 148 314 156 295 158 C 292 195 285 260 270 318
        C 255 372 225 398 178 398 C 134 398 112 362 114 322
        C 116 288 140 270 162 272 C 180 274 188 290 184 308
        C 178 334 162 346 154 348 C 160 360 172 368 192 366
        C 220 362 242 334 250 285 C 260 225 264 170 265 146
        C 230 152 194 162 174 170 C 165 174 158 164 164 154
        C 167 148 171 144 175 142 Z" />
    </clipPath>
  </defs>

  <!-- Sticky Note Body -->
  <g filter="url(#note-shadow)">
    <path d="M 112 40 L 352 40 Q 360 40 366 46 L 466 146 Q 472 152 472 160 L 472 400 C 472 440 440 472 400 472 L 112 472 C 72 472 40 440 40 400 L 40 112 C 40 72 72 40 112 40 Z"
          fill="url(#note-grad)" />
  </g>

  {hazard_footer}

  <!-- Dog-Ear Corner -->
  <path d="M 352 40 C 352 95 365 160 472 160 L 366 46 Z"
        fill="url(#fold-grad)" filter="url(#dogear-shadow)" />

  <!-- Medium-Density Hatches -->
  <g clip-path="url(#j-clip)" stroke="{cfg['ink_primary']}" stroke-width="8" stroke-linecap="round">
    <line x1="160" y1="120" x2="240" y2="200" />
    <line x1="200" y1="110" x2="280" y2="190" />
    <line x1="240" y1="100" x2="320" y2="180" />
    <line x1="280" y1="90"  x2="360" y2="170" />
    <line x1="210" y1="160" x2="310" y2="260" />
    <line x1="190" y1="200" x2="290" y2="300" />
    <line x1="170" y1="240" x2="270" y2="340" />
    <line x1="150" y1="280" x2="250" y2="380" />
    <line x1="130" y1="310" x2="230" y2="410" />
    <line x1="100" y1="310" x2="200" y2="410" />
    <line x1="90"  y1="270" x2="190" y2="370" />
    <line x1="110" y1="240" x2="210" y2="340" />
  </g>

  <!-- Outline -->
  <path d="
    M 175 142 C 210 134 260 126 325 120 C 334 119 340 126 336 135
    C 330 148 314 156 295 158 C 292 195 285 260 270 318
    C 255 372 225 398 178 398 C 134 398 112 362 114 322
    C 116 288 140 270 162 272 C 180 274 188 290 184 308
    C 178 334 162 346 154 348 C 160 360 172 368 192 366
    C 220 362 242 334 250 285 C 260 225 264 170 265 146
    C 230 152 194 162 174 170 C 165 174 158 164 164 154
    C 167 148 171 144 175 142 Z"
    fill="none" stroke="{cfg['ink_dark']}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round" />

  {accent}
</svg>'''

    # 3. Size Tier: Large (64px, 128px, scalable.svg)
    else:
        with open('data/icons/concept/jots-icon.svg', 'r') as f:
            concept_svg = f.read()

        h_start = concept_svg.find('<!-- 1. Ultra-Dense Organic Ballpoint Hatching')
        h_end = concept_svg.find('<!-- 2. Primary Hand-Drawn Biro Outline')
        hatch_block = concept_svg[h_start:h_end]

        hatch_block = hatch_block.replace('#0E3D9E', cfg['ink_primary'])
        hatch_block = hatch_block.replace('#0B3082', cfg['ink_dark'])
        hatch_block = hatch_block.replace('#09266B', cfg['ink_accent'])

        return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <defs>
    <filter id="note-shadow" x="-10%" y="-10%" width="125%" height="130%" filterUnits="userSpaceOnUse">
      <feDropShadow dx="0" dy="18" stdDeviation="16" flood-color="#141005" flood-opacity="0.16" />
      <feDropShadow dx="0" dy="4" stdDeviation="6" flood-color="#141005" flood-opacity="0.09" />
    </filter>
    <filter id="dogear-shadow" x="-30%" y="-30%" width="160%" height="160%">
      <feDropShadow dx="-6" dy="10" stdDeviation="8" flood-color="#3A2800" flood-opacity="0.22" />
      <feDropShadow dx="-2" dy="3" stdDeviation="3" flood-color="#3A2800" flood-opacity="0.12" />
    </filter>
    <linearGradient id="note-grad" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="{cfg['paper_start']}" />
      <stop offset="40%" stop-color="{cfg['paper_mid']}" />
      <stop offset="100%" stop-color="{cfg['paper_end']}" />
    </linearGradient>
    <linearGradient id="fold-grad" x1="0%" y1="100%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="{cfg['fold_start']}" />
      <stop offset="45%" stop-color="{cfg['fold_mid']}" />
      <stop offset="100%" stop-color="{cfg['fold_end']}" />
    </linearGradient>
    <clipPath id="note-outline-clip">
      <path d="M 112 40 L 352 40 Q 360 40 366 46 L 466 146 Q 472 152 472 160 L 472 400 C 472 440 440 472 400 472 L 112 472 C 72 472 40 440 40 400 L 40 112 C 40 72 72 40 112 40 Z" />
    </clipPath>
    <clipPath id="hazard-band-clip-large">
      <path d="M 40 432 L 472 432 L 472 400 C 472 440 440 472 400 472 L 112 472 C 72 472 40 440 40 400 Z" />
    </clipPath>
    <clipPath id="j-natural-clip">
      <path d="
        M 175 142 C 210 134 260 126 325 120 C 334 119 340 126 336 135
        C 330 148 314 156 295 158 C 292 195 285 260 270 318
        C 255 372 225 398 178 398 C 134 398 112 362 114 322
        C 116 288 140 270 162 272 C 180 274 188 290 184 308
        C 178 334 162 346 154 348 C 160 360 172 368 192 366
        C 220 362 242 334 250 285 C 260 225 264 170 265 146
        C 230 152 194 162 174 170 C 165 174 158 164 164 154
        C 167 148 171 144 175 142 Z" />
    </clipPath>
  </defs>

  <!-- Sticky Note Body -->
  <g filter="url(#note-shadow)">
    <path d="M 112 40 L 352 40 Q 360 40 366 46 L 466 146 Q 472 152 472 160 L 472 400 C 472 440 440 472 400 472 L 112 472 C 72 472 40 440 40 400 L 40 112 C 40 72 72 40 112 40 Z"
          fill="url(#note-grad)" />
  </g>

  {hazard_footer}

  <!-- Dog-Ear Corner -->
  <path d="M 352 40 C 352 95 365 160 472 160 L 366 46 Z"
        fill="url(#fold-grad)" filter="url(#dogear-shadow)" />

  {hatch_block}

  <!-- Outline -->
  <path d="
    M 175 142 C 210 134 260 126 325 120 C 334 119 340 126 336 135
    C 330 148 314 156 295 158 C 292 195 285 260 270 318
    C 255 372 225 398 178 398 C 134 398 112 362 114 322
    C 116 288 140 270 162 272 C 180 274 188 290 184 308
    C 178 334 162 346 154 348 C 160 360 172 368 192 366
    C 220 362 242 334 250 285 C 260 225 264 170 265 146
    C 230 152 194 162 174 170 C 165 174 158 164 164 154
    C 167 148 171 144 175 142 Z"
    fill="none" stroke="{cfg['ink_dark']}" stroke-width="6.5" stroke-linecap="round" stroke-linejoin="round" />

  <!-- Accent Trace Line -->
  <path d="
    M 178 143 C 214 135 262 127 322 121
    M 293 160 C 290 198 283 262 268 320
    C 253 374 223 396 178 396 C 136 396 115 360 116 322
    C 118 290 140 272 160 274
    M 222 360 C 244 330 252 282 262 220
    C 265 168 266 148 265 148 C 232 153 196 163 176 171"
    fill="none" stroke="{cfg['ink_accent']}" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" opacity="0.75" />

  {accent}
</svg>'''


def main():
    print("Generating SVG icons across all variants and size tiers...")
    for variant in VARIANTS.keys():
        vdir = os.path.join('data', 'icons', variant)
        os.makedirs(vdir, exist_ok=True)
        os.makedirs(os.path.join(vdir, 'hicolor'), exist_ok=True)
        os.makedirs(os.path.join(vdir, 'hicolor@2'), exist_ok=True)

        scalable_svg = generate_svg_markup(variant, size_tier='large')
        with open(os.path.join(vdir, 'scalable.svg'), 'w') as f:
            f.write(scalable_svg)

        for sz in SIZES:
            tier = 'small' if sz <= 24 else ('medium' if sz <= 48 else 'large')
            svg_content = generate_svg_markup(variant, size_tier=tier)
            with open(os.path.join(vdir, f'{sz}.svg'), 'w') as f:
                f.write(svg_content)

        print(f"  [OK] Generated SVGs for variant: {variant}")


if __name__ == '__main__':
    main()
