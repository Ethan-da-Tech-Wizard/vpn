const express = require('express');
const path = require('path');
const fs = require('fs');
const { exec } = require('child_process');
const QRCode = require('qrcode');

const app = express();
const PORT = process.env.PORT || 3000;
const BASE_DIR = path.join(__dirname, '..');
const CLIENTS_DIR = path.join(BASE_DIR, 'clients');
const MANAGE_SCRIPT = path.join(BASE_DIR, 'manage-vpn.sh');

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Helper to execute bash commands safely
function runCmd(cmd) {
    return new Promise((resolve, reject) => {
        exec(cmd, { cwd: BASE_DIR }, (error, stdout, stderr) => {
            if (error) resolve({ error: error.message, stdout, stderr });
            else resolve({ stdout: stdout.trim(), stderr: stderr.trim() });
        });
    });
}

// GET /api/status
app.get('/api/status', async (req, res) => {
    try {
        const ipRes = await runCmd('curl -s4 https://ifconfig.me || curl -s4 https://api.ipify.org || echo "Unknown IP"');
        const wgRes = await runCmd('wg show 2>/dev/null || echo "WireGuard Ready"');
        const clients = fs.existsSync(CLIENTS_DIR) ? fs.readdirSync(CLIENTS_DIR).filter(f => f.endsWith('.conf')) : [];
        
        res.json({
            status: 'online',
            publicIp: ipRes.stdout || '127.0.0.1',
            protocol: 'WireGuard (ChaCha20-Poly1305)',
            dnsProtection: 'Cloudflare 1.1.1.1 + Quad9 9.9.9.9 (Anti-Leak)',
            clientCount: clients.length,
            wireguardRaw: wgRes.stdout
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// GET /api/clients
app.get('/api/clients', (req, res) => {
    if (!fs.existsSync(CLIENTS_DIR)) {
        return res.json([]);
    }

    const files = fs.readdirSync(CLIENTS_DIR).filter(f => f.endsWith('.conf'));
    const clients = files.map(file => {
        const name = path.basename(file, '.conf');
        const content = fs.readFileSync(path.join(CLIENTS_DIR, file), 'utf8');
        const ipMatch = content.match(/Address\s*=\s*([^\n,]+)/);
        const assignedIp = ipMatch ? ipMatch[1].trim() : 'Unknown';
        const stats = fs.statSync(path.join(CLIENTS_DIR, file));
        return {
            name,
            ip: assignedIp,
            created: stats.birthtime || stats.ctime,
            file
        };
    });

    res.json(clients);
});

// POST /api/clients/create
app.post('/api/clients/create', async (req, res) => {
    const { name } = req.body;
    if (!name || typeof name !== 'string') {
        return res.status(400).json({ error: 'Client name is required.' });
    }

    const safeName = name.replace(/[^a-zA-Z0-9_-]/g, '');
    if (!safeName) {
        return res.status(400).json({ error: 'Invalid name format.' });
    }

    const result = await runCmd(`bash "${MANAGE_SCRIPT}" add "${safeName}"`);
    if (result.error && !result.stdout.includes('Successfully created')) {
        return res.status(500).json({ error: result.error, stderr: result.stderr });
    }

    res.json({ success: true, name: safeName, message: `Created VPN profile: ${safeName}` });
});

// GET /api/clients/:name/qr
app.get('/api/clients/:name/qr', async (req, res) => {
    const safeName = req.params.name.replace(/[^a-zA-Z0-9_-]/g, '');
    const confPath = path.join(CLIENTS_DIR, `${safeName}.conf`);

    if (!fs.existsSync(confPath)) {
        return res.status(404).json({ error: 'Client profile not found.' });
    }

    const content = fs.readFileSync(confPath, 'utf8');
    try {
        const qrDataUrl = await QRCode.toDataURL(content, { margin: 2, scale: 6 });
        res.json({ name: safeName, qrDataUrl, rawConfig: content });
    } catch (err) {
        res.status(500).json({ error: 'Failed to generate QR code.' });
    }
});

// GET /api/clients/:name/download
app.get('/api/clients/:name/download', (req, res) => {
    const safeName = req.params.name.replace(/[^a-zA-Z0-9_-]/g, '');
    const confPath = path.join(CLIENTS_DIR, `${safeName}.conf`);

    if (!fs.existsSync(confPath)) {
        return res.status(404).json({ error: 'Client profile not found.' });
    }

    res.download(confPath, `${safeName}.conf`);
});

// DELETE /api/clients/:name
app.delete('/api/clients/:name', async (req, res) => {
    const safeName = req.params.name.replace(/[^a-zA-Z0-9_-]/g, '');
    const result = await runCmd(`bash "${MANAGE_SCRIPT}" revoke "${safeName}"`);
    
    res.json({ success: true, message: `Revoked profile: ${safeName}` });
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`[VPN Dashboard] Running on http://0.0.0.0:${PORT}`);
});
