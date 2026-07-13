import sharp from 'sharp';
import { readFileSync, mkdirSync, copyFileSync } from 'fs';

const density = 512;

async function svgToPng(svgPath, outPath, size, bg) {
    const svg = readFileSync(svgPath);
    let img = sharp(svg, { density });
    img = img.resize(size, size, {
        fit: 'contain',
        background: bg || { r: 0, g: 0, b: 0, alpha: 0 },
    });
    if (bg) img = img.flatten({ background: bg });
    await img.png().toFile(outPath);
    console.log('OK ->', outPath, size);
}

function ensure(dir) { mkdirSync(dir, { recursive: true }); }

const mobile = '../mobile/assets/branding';
const web = '../frontend/public';
ensure(mobile);
ensure(web);
ensure('out');

await svgToPng('app_icon.svg', `${mobile}/app_icon.png`, 1024);
await svgToPng('icon_foreground.svg', `${mobile}/icon_foreground.png`, 1024);
await svgToPng('mark.svg', `${mobile}/mark.png`, 1024);

await svgToPng('app_icon.svg', `${web}/favicon.png`, 256);
await svgToPng('app_icon.svg', `${web}/apple-touch-icon.png`, 180);
copyFileSync('app_icon.svg', `${web}/favicon.svg`);
copyFileSync('mark.svg', `${web}/mark.svg`);
copyFileSync('app_icon.svg', `${web}/app_icon.svg`);

await svgToPng('icon_foreground.svg', 'out/icon_foreground.png', 512);
console.log('done');
