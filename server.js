// server.js - Master Coexistence Server for Triyog High School
const express = require('express');
const path = require('path');
const cors = require('cors');
const fs = require('fs');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;

// 1. Security Headers Middleware
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'SAMEORIGIN');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
  next();
});

// 2. Sensitive Path & Dotfile Protection (Strict Blocking)
app.use((req, res, next) => {
  const lowerUrl = req.path.toLowerCase();

  // Block any dotfiles (.env, .git, .gitignore, etc.)
  if (lowerUrl.includes('/.') || lowerUrl.startsWith('/.') || lowerUrl.startsWith('.')) {
    return res.status(404).send('Not Found');
  }

  // Block server internals, credentials, source code, node_modules, and scripts
  const blockedPatterns = [
    /\.env/i,
    /package(-lock)?\.json/i,
    /server\.js/i,
    /schema\.sql/i,
    /^\/src(\/|$)/i,
    /^\/node_modules(\/|$)/i,
    /\.bat$/i,
    /\.md$/i
  ];

  for (const pattern of blockedPatterns) {
    if (pattern.test(lowerUrl)) {
      return res.status(404).send('Not Found');
    }
  }
  next();
});

// 3. Cross-Origin Resource Sharing & Body Parsers
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// 4. In-Memory Sliding-Window Rate Limiter Middleware
function createRateLimiter({ windowMs, max, message }) {
  const hits = new Map();

  // Periodic cleanup of expired window entries every 5 minutes
  setInterval(() => {
    const now = Date.now();
    for (const [key, entry] of hits.entries()) {
      if (now - entry.startTime > windowMs) {
        hits.delete(key);
      }
    }
  }, 5 * 60 * 1000).unref();

  return (req, res, next) => {
    const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress || '127.0.0.1';
    const now = Date.now();
    const entry = hits.get(ip);

    if (!entry || (now - entry.startTime > windowMs)) {
      hits.set(ip, { count: 1, startTime: now });
      return next();
    }

    entry.count += 1;
    if (entry.count > max) {
      const retryAfter = Math.ceil((entry.startTime + windowMs - now) / 1000);
      res.setHeader('Retry-After', retryAfter);
      return res.status(429).json({ error: message || 'Too many requests, please try again later.' });
    }

    next();
  };
}

const authLimiter = createRateLimiter({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10,                   // 10 login attempts per 15 min per IP
  message: 'Too many authentication attempts from this IP. Please try again after 15 minutes.'
});

const apiLimiter = createRateLimiter({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 200,                  // 200 API calls per 15 min per IP
  message: 'API rate limit exceeded. Please try again later.'
});

// 5. Ensure local disk upload directories exist
const uploadDirs = [
  path.join(__dirname, 'public/uploads/notices'),
  path.join(__dirname, 'public/uploads/routines'),
  path.join(__dirname, 'public/uploads/gallery'),
  path.join(__dirname, 'public/uploads/publication')
];
uploadDirs.forEach(dir => {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
});

// 6. Serve Local Disk Storage at /uploads (Ignoring dotfiles)
app.use('/uploads', express.static(path.join(__dirname, 'public/uploads'), { dotfiles: 'ignore' }));

// 7. Serve Public Static Asset Directories (Ignoring dotfiles)
app.use('/css', express.static(path.join(__dirname, 'css'), { dotfiles: 'ignore' }));
app.use('/fonts', express.static(path.join(__dirname, 'fonts'), { dotfiles: 'ignore' }));
app.use('/images', express.static(path.join(__dirname, 'images'), { dotfiles: 'ignore' }));
app.use('/js', express.static(path.join(__dirname, 'js'), { dotfiles: 'ignore' }));
app.use('/media', express.static(path.join(__dirname, 'media'), { dotfiles: 'ignore' }));
if (fs.existsSync(path.join(__dirname, 'components'))) {
  app.use('/components', express.static(path.join(__dirname, 'components'), { dotfiles: 'ignore' }));
}

// 8. Mount Dynamic REST API Routes with Rate Limiting
app.use('/api', apiLimiter);
app.use('/api/auth/login', authLimiter);
app.use('/api/auth', require('./src/routes/auth'));
app.use('/api/upload', require('./src/routes/upload'));
app.use('/api/notices', require('./src/routes/notices'));
app.use('/api/events', require('./src/routes/events'));
app.use('/api/cas', require('./src/routes/cas'));
app.use('/api/homework', require('./src/routes/homework'));

// 9. Dynamic Portal Routes (Supports clean URLs and .html extensions)
app.get(['/principal', '/principal.html'], (req, res) => {
  res.sendFile(path.join(__dirname, 'principal.html'));
});

app.get(['/login', '/login.html'], (req, res) => {
  res.redirect('/admin.html');
});

app.get(['/admin', '/admin.html'], (req, res) => {
  res.sendFile(path.join(__dirname, 'admin.html'));
});

app.get(['/teacher', '/teacher.html'], (req, res) => {
  res.sendFile(path.join(__dirname, 'teacher.html'));
});

app.get(['/student', '/student.html', '/student-portal', '/student-portal.html'], (req, res) => {
  res.sendFile(path.join(__dirname, 'student-portal.html'));
});

app.get(['/customizer', '/customizer.html'], (req, res) => {
  res.sendFile(path.join(__dirname, 'customizer.html'));
});

// 10. Public Frontend Static Routes (Clean URLs and HTML files)
const serveHtmlIfExists = (file, res, next) => {
  const fullPath = path.join(__dirname, file);
  if (fs.existsSync(fullPath)) {
    return res.sendFile(fullPath);
  }
  return next();
};

app.get(['/', '/index.html'], (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

app.get(['/about', '/about.html'], (req, res, next) => serveHtmlIfExists('about.html', res, next));
app.get(['/admissions', '/admissions.html'], (req, res, next) => serveHtmlIfExists('admissions.html', res, next));
app.get(['/academics', '/academics.html'], (req, res, next) => serveHtmlIfExists('academics.html', res, next));
app.get(['/contact', '/contact.html'], (req, res, next) => serveHtmlIfExists('contact.html', res, next));
app.get(['/file-manager', '/file-manager.html', '/downloads', '/downloads.html'], (req, res, next) => serveHtmlIfExists('file-manager.html', res, next));
app.get(['/404', '/404.html'], (req, res, next) => serveHtmlIfExists('404.html', res, next));

// 11. Whitelist-Protected Root Static Assets (logo.jpg, favicon.ico, images in root)
const ALLOWED_ROOT_EXTENSIONS = new Set(['.jpg', '.jpeg', '.png', '.gif', '.svg', '.ico', '.txt', '.pdf', '.webp']);
app.get('/:filename', (req, res, next) => {
  const filename = req.params.filename;
  const ext = path.extname(filename).toLowerCase();

  if (!ALLOWED_ROOT_EXTENSIONS.has(ext)) {
    return next();
  }

  const safePath = path.join(__dirname, path.basename(filename));
  if (fs.existsSync(safePath) && fs.statSync(safePath).isFile()) {
    return res.sendFile(safePath);
  }
  next();
});

// 12. Custom 404 Handler
app.use((req, res) => {
  if (req.path.startsWith('/api/')) {
    return res.status(404).json({ error: 'API endpoint not found.' });
  }
  const notFoundPath = path.join(__dirname, '404.html');
  if (fs.existsSync(notFoundPath)) {
    return res.status(404).sendFile(notFoundPath);
  }
  return res.status(404).send('Page Not Found');
});

// 13. Global Error Handler (Sanitizes internal server errors and stack traces)
app.use((err, req, res, next) => {
  console.error('[Unhandled Server Error]', err);
  if (res.headersSent) {
    return next(err);
  }
  if (req.path.startsWith('/api/')) {
    return res.status(err.status || 500).json({ error: 'An unexpected internal server error occurred.' });
  }
  const notFoundPath = path.join(__dirname, '404.html');
  if (fs.existsSync(notFoundPath)) {
    return res.status(500).sendFile(notFoundPath);
  }
  return res.status(500).send('Internal Server Error');
});

// Start server
app.listen(PORT, () => {
  console.log('====================================================');
  console.log(`🚀 Pegasus School Portal Engine running on port ${PORT}`);
  console.log(`👉 Public Homepage:   http://localhost:${PORT}/`);
  console.log(`👉 Admin CMS:         http://localhost:${PORT}/admin (ID: admin / PW: admin)`);
  console.log(`👉 Principal Suite:   http://localhost:${PORT}/principal (ID: principal / PW: principal)`);
  console.log(`👉 Teacher Panel:     http://localhost:${PORT}/teacher (ID: teacher / PW: teacher)`);
  console.log(`👉 Student Portal:    http://localhost:${PORT}/student`);
  console.log(`👉 Dynamic Notices:   http://localhost:${PORT}/api/notices`);
  console.log(`👉 Dynamic Events:    http://localhost:${PORT}/api/events`);
  console.log('====================================================');
});
