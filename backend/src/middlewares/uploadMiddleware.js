const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const multer = require('multer');

// Pasta de destino: backend/uploads/ativos
const UPLOAD_DIR = path.join(__dirname, '..', '..', 'uploads', 'ativos');
fs.mkdirSync(UPLOAD_DIR, { recursive: true });

const TIPOS_PERMITIDOS = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];

const storage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, UPLOAD_DIR),
    filename: (req, file, cb) => {
        const ext = path.extname(file.originalname).toLowerCase().slice(0, 10);
        const nome = crypto.randomBytes(16).toString('hex');
        cb(null, `${Date.now()}-${nome}${ext}`);
    },
});

function fileFilter(req, file, cb) {
    if (!TIPOS_PERMITIDOS.includes(file.mimetype)) {
        const err = new Error('Formato de imagem invalido (use JPG, PNG, WEBP ou GIF)');
        err.code = 'VAL_003';
        return cb(err);
    }
    cb(null, true);
}

const uploadImagem = multer({
    storage,
    fileFilter,
    limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB
});

module.exports = { uploadImagem, UPLOAD_DIR };
