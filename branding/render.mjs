import sharp from 'sharp';
import { readFileSync } from 'fs';

async function render(svgPath, outPath, size) {
    const svg = readFileSync(svgPath);
    await sharp(svg, { density: 384 })
        .resize(size, size, { fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 } })
        .png()
        .toFile(outPath);
    console.log('OK ->', outPath, size);
}

await render('app_icon.svg', 'out/app_icon.png', 1024);
