//
//  MarsRoverView.swift
//  GalacticalMap
//
//  Mars Rover canlı veri ve fotoğraflar
//

import SwiftUI
import WebKit
import SafariServices
import CoreMotion

struct MarsRoverView: View {
    @State private var selectedRover: MarsRover = .perseverance
    @State private var photos: [RoverPhoto] = []
    @State private var roverStatus: RoverStatus?
    @State private var selectedPhoto: RoverPhoto?
    @State private var showGyroVR: Bool
    @State private var requestedGyroOnce: Bool = false
    @State private var injectedHTML: String = ""
    private let gyroHTML = """
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<title>Perseverance Live Photos VR</title>
<style>
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: 'Courier New', monospace; background: #000; overflow: hidden; color: white; }
#container { width: 100vw; height: 100vh; position: relative; }
#info { position: absolute; top: 20px; left: 50%; transform: translateX(-50%); background: rgba(0,0,0,0.9); padding: 20px 40px; border-radius: 12px; text-align: center; z-index: 100; border: 2px solid #ff4500; max-width: 90vw; }
#info h1 { color: #ff4500; font-size: 22px; margin-bottom: 10px; text-transform: uppercase; }
#info .subtitle { color: #888; font-size: 11px; margin-bottom: 15px; }
.warning { background: rgba(255,69,0,0.2); padding: 12px; border-radius: 8px; border-left: 3px solid #ff4500; margin-top: 10px; font-size: 11px; line-height: 1.6; text-align: left; }
.warning-title { color: #ff4500; font-weight: bold; margin-bottom: 5px; }
#photoInfo { position: absolute; bottom: 20px; left: 20px; background: rgba(0,0,0,0.9); padding: 15px 20px; border-radius: 10px; z-index: 100; max-width: 400px; border: 1px solid #ff4500; }
.photo-detail { margin: 5px 0; font-size: 12px; }
.photo-detail strong { color: #ff4500; display: inline-block; width: 80px; }
                #controls { position: absolute; bottom: 20px; right: 20px; background: rgba(0,0,0,0.9); padding: 15px; border-radius: 10px; z-index: 100; text-align: center; border: 1px solid #ff4500; }
                .control-btn { background: #ff4500; color: white; border: none; padding: 10px 20px; border-radius: 5px; cursor: pointer; margin: 5px; font-size: 12px; font-weight: bold; }
                .control-btn:hover { background: #ff6600; }
                #gyroStatus { position: absolute; top: 120px; right: 20px; background: rgba(255,69,0,0.9); padding: 10px 20px; border-radius: 8px; font-size: 12px; z-index: 100; }
                #loading { position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); font-size: 18px; color: #ff4500; z-index: 200; text-align: center; background: rgba(0,0,0,0.95); padding: 30px 50px; border-radius: 15px; border: 2px solid #ff4500; }
                .loading-spinner { width: 50px; height: 50px; border: 4px solid rgba(255,69,0,0.3); border-top: 4px solid #ff4500; border-radius: 50%; animation: spin 1s linear infinite; margin: 20px auto; }
                @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
                .crosshair { position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); width: 30px; height: 30px; border: 2px solid rgba(255,69,0,0.6); border-radius: 50%; pointer-events: none; z-index: 50; }
                .crosshair::before { content: ''; position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); width: 6px; height: 6px; background: #ff4500; border-radius: 50%; }
                #photoGallery { position: absolute; top: 20px; right: 20px; background: rgba(0,0,0,0.9); padding: 10px; border-radius: 10px; z-index: 100; max-height: 150px; overflow-y: auto; border: 1px solid #ff4500; }
                .thumbnail { width: 60px; height: 60px; margin: 5px; cursor: pointer; border: 2px solid #555; border-radius: 5px; object-fit: cover; transition: border-color 0.3s; }
                .thumbnail:hover { border-color: #ff4500; }
.thumbnail.active { border-color: #ff4500; box-shadow: 0 0 10px #ff4500; }
#info, #photoInfo, #controls, #photoGallery, #gyroStatus, #loading, #permissionGate { display: none !important; }
                #permissionGate { position: absolute; inset: 0; display: none; align-items: center; justify-content: center; background: rgba(0,0,0,0.95); z-index: 300; }
                #permissionGate .panel { border: 2px solid #ff4500; padding: 20px 24px; border-radius: 12px; text-align: center; max-width: 80vw; }
                #permissionGate .title { color: #ff4500; font-weight: bold; margin-bottom: 8px; }
                #permissionGate .desc { color: #aaa; font-size: 12px; margin-bottom: 12px; }
                #permissionGate .btn { background: #ff4500; color: #fff; border: none; padding: 10px 20px; border-radius: 6px; font-weight: bold; }
            </style>
</head>
<body>
<div id="container">
<div id="loading">
<div class="loading-spinner"></div>
<div>🔴 Loading latest Mars photos from NASA...</div>
<small style="color: #888; margin-top: 10px; display: block;"> Fetching real images from Perseverance Rover </small>
</div>
<div id="info" style="display: none;">
<h1>🤖 PERSEVERANCE ROVER</h1>
<div class="subtitle">LIVE PHOTOS FROM MARS - JEZERO CRATER</div>
<div class="warning">
<div class="warning-title">⚠️ COMMUNICATION DELAY</div>
Mars to Earth signal transmission takes 5-20 minutes.<br>
Photos are updated daily as NASA receives new transmissions.<br>
These are REAL images captured by Perseverance's cameras.
</div>
</div>
<div class="crosshair"></div>
<div id="gyroStatus" style="display: none;">
📱 Gyroscope: <span id="gyroText">Starting...</span>
</div>
<div id="photoInfo" style="display: none;">
<div class="photo-detail"><strong>SOL:</strong> <span id="sol">--</span></div>
<div class="photo-detail"><strong>Camera:</strong> <span id="camera">--</span></div>
<div class="photo-detail"><strong>Date:</strong> <span id="earthDate">--</span></div>
<div class="photo-detail"><strong>Total Photos:</strong> <span id="totalPhotos">--</span></div>
</div>
<div id="photoGallery" style="display: none;"></div>
            <div id="controls" style="display: none;">
                <div style="color: #888; font-size: 11px; margin-bottom: 10px;">CONTROLS</div>
                <button class="control-btn" onclick="prevPhoto()">◄ PREV</button>
                <button class="control-btn" onclick="nextPhoto()">NEXT ►</button>
                <button class="control-btn" onclick="enableGyro()">📱 ENABLE GYRO</button>
                <button class="control-btn" onclick="calibrateGyro()">🎯 CALIBRATE</button>
                <button class="control-btn" onclick="zoomIn()">🔍 ZOOM +</button>
                <button class="control-btn" onclick="zoomOut()">🔎 ZOOM -</button>
                <button class="control-btn" onclick="restartVR()">♻️ RESTART</button>
            </div>
            <div id="permissionGate" onclick="enableGyroAndHide()">
                <div class="panel">
                    <div class="title">Motion & Orientation İzni</div>
                    <div class="desc">Sensör kontrollerini etkinleştirmek için bir kez izin verin.</div>
                    <button class="btn" onclick="enableGyroAndHide()">İZİN VER</button>
                </div>
            </div>
        </div>
<script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
        <script>
let scene, camera, renderer, photoSphere;
let gyroEnabled = false;
let photos = [];
let currentPhotoIndex = 0;
let alpha = 0, beta = 0, gamma = 0;
let mouseDown = false;
let previousMouseX = 0, previousMouseY = 0;
        const NASA_API_KEY = 'DEMO_KEY';
        const TEXTURE_CANDIDATES = [
            'https://unpkg.com/three@0.128.0/examples/textures/planets/mars_1024.jpg',
            'https://cdn.jsdelivr.net/gh/mrdoob/three.js@r128/examples/textures/planets/mars_1024.jpg',
            'https://raw.githubusercontent.com/mrdoob/three.js/r128/examples/textures/planets/mars_1024.jpg',
            'https://threejs.org/examples/textures/planets/mars_1024.jpg'
        ];
        const PLACEHOLDER_IMG = 'MARS_TEXTURE';
const SAMPLE_PHOTOS = [
    { img_src: 'https://images-assets.nasa.gov/image/PIA24265/PIA24265~orig.jpg', sol: 1000, earth_date: '2024-05-01', camera: { name: 'NAVCAM', full_name: 'Navigation Camera' } },
    { img_src: 'https://images-assets.nasa.gov/image/PIA24426/PIA24426~orig.jpg', sol: 999, earth_date: '2024-04-30', camera: { name: 'MASTCAM', full_name: 'Mast Camera' } },
    { img_src: 'https://images-assets.nasa.gov/image/PIA24428/PIA24428~orig.jpg', sol: 998, earth_date: '2024-04-29', camera: { name: 'FHAZ', full_name: 'Front Hazard Camera' } },
    { img_src: 'https://images-assets.nasa.gov/image/PIA24645/PIA24645~orig.jpg', sol: 997, earth_date: '2024-04-28', camera: { name: 'RHAZ', full_name: 'Rear Hazard Camera' } },
    { img_src: 'https://images-assets.nasa.gov/image/PIA24546/PIA24546~orig.jpg', sol: 996, earth_date: '2024-04-27', camera: { name: 'CHEMCAM', full_name: 'Chemistry Camera' } },
    { img_src: 'https://images-assets.nasa.gov/image/PIA24264/PIA24264~orig.jpg', sol: 995, earth_date: '2024-04-26', camera: { name: 'MAHLI', full_name: 'Mars Hand Lens Imager' } }
];
const SMOOTH = 0.08;
let sAlpha = 0, sBeta = 0, sGamma = 0;
let offAlpha = 0, offBeta = 0, offGamma = 0;

function createProceduralMarsTexture() {
    const w = 2048, h = 1024;
    const canvas = document.createElement('canvas');
    canvas.width = w; canvas.height = h;
    const ctx = canvas.getContext('2d');
    const grad = ctx.createLinearGradient(0, 0, 0, h);
    grad.addColorStop(0, '#5a220a');
    grad.addColorStop(0.5, '#7b2f12');
    grad.addColorStop(1, '#3f1707');
    ctx.fillStyle = grad; ctx.fillRect(0, 0, w, h);
    // Basit gürültü
    const imgData = ctx.getImageData(0, 0, w, h);
    const d = imgData.data;
    for (let y = 0; y < h; y++) {
        for (let x = 0; x < w; x++) {
            const i = (y * w + x) * 4;
            const n = (Math.sin(x * 0.01) + Math.cos(y * 0.015)) * 8 + (Math.random() - 0.5) * 6;
            d[i]   = Math.min(255, Math.max(0, d[i] + n));
            d[i+1] = Math.min(255, Math.max(0, d[i+1] + n * 0.7));
            d[i+2] = Math.min(255, Math.max(0, d[i+2] + n * 0.4));
        }
    }
    ctx.putImageData(imgData, 0, 0);
    const tex = new THREE.CanvasTexture(canvas);
    tex.wrapS = THREE.RepeatWrapping;
    tex.wrapT = THREE.ClampToEdgeWrapping;
    tex.needsUpdate = true;
    return tex;
}

async function loadTextureViaFetch(u) {
    const res = await fetch(u, { cache: 'no-store' });
    if (!res.ok) throw new Error('fetch failed');
    const blob = await res.blob();
    const bmp = await createImageBitmap(blob);
    const tex = new THREE.Texture(bmp);
    tex.needsUpdate = true;
    return tex;
}

        async function init() {
            scene = new THREE.Scene();
            camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
            camera.position.set(0, 0, 0.1);
            renderer = new THREE.WebGLRenderer({ antialias: true });
            renderer.setPixelRatio(Math.min(2, window.devicePixelRatio || 1));
            renderer.setSize(window.innerWidth, window.innerHeight);
            renderer.setClearColor(0x000000, 1);
            document.getElementById('container').appendChild(renderer.domElement);
            photos = [{ img_src: PLACEHOLDER_IMG, sol: 0, earth_date: '', camera: { name: 'GLOBAL', full_name: 'Mars Global Map' } }];
            loadPhoto(0);
            setupControls();
            // permissionGate removed for minimal UI
            window.addEventListener('resize', () => {
                camera.aspect = window.innerWidth / window.innerHeight;
                camera.updateProjectionMatrix();
                renderer.setSize(window.innerWidth, window.innerHeight);
            });
            animate();
        }

async function fetchMarsPhotos() {
try {
const controller = new AbortController();
const timer = setTimeout(() => controller.abort(), 8000);
const response = await fetch(`https://api.nasa.gov/mars-photos/api/v1/rovers/perseverance/latest_photos?api_key=${NASA_API_KEY}`,{ cache: 'no-store', signal: controller.signal });
clearTimeout(timer);
const data = await response.json();
if (data.latest_photos && data.latest_photos.length > 0) {
photos = data.latest_photos.filter(photo =>
photo.camera.name.includes('NAVCAM') ||
photo.camera.name.includes('FRONT_HAZCAM') ||
photo.camera.name.includes('REAR_HAZCAM') ||
photo.camera.name.includes('MCZ')
).slice(0, 20);
photos = photos.map(p => ({ ...p, img_src: (p.img_src || '').replace('http://', 'https://') }));
if (photos.length === 0) { photos = data.latest_photos.slice(0, 20); }
photos = photos.map(p => ({ ...p, img_src: (p.img_src || '').replace('http://', 'https://') }));
loadPhoto(0);
createThumbnails();
document.getElementById('loading').style.display = 'none';
document.getElementById('info').style.display = 'block';
document.getElementById('photoInfo').style.display = 'block';
document.getElementById('controls').style.display = 'block';
document.getElementById('photoGallery').style.display = 'block';
setTimeout(() => { document.getElementById('info').style.display = 'none'; }, 5000);
} else { throw new Error('No photos found'); }
} catch (error) {
photos = SAMPLE_PHOTOS.map(p => ({ ...p, img_src: (p.img_src || '').replace('http://','https://') }));
loadPhoto(0);
createThumbnails();
document.getElementById('loading').style.display = 'none';
document.getElementById('info').style.display = 'block';
document.getElementById('photoInfo').style.display = 'block';
document.getElementById('controls').style.display = 'block';
document.getElementById('photoGallery').style.display = 'block';
setTimeout(() => { document.getElementById('info').style.display = 'none'; }, 5000);
}
}

function loadPhoto(index) {
currentPhotoIndex = index;
const photo = photos[index];
if (photoSphere) {
scene.remove(photoSphere);
photoSphere.geometry.dispose();
photoSphere.material.dispose();
}
const geometry = new THREE.SphereGeometry(500, 60, 40);
geometry.scale(-1, 1, 1);
        const textureLoader = new THREE.TextureLoader();
        textureLoader.setCrossOrigin('anonymous');
        const urls = [photo.img_src].concat(TEXTURE_CANDIDATES);
        let idx = 0;
        const tryNext = async () => {
            if (idx >= urls.length) {
                const tex = createProceduralMarsTexture();
                const material = new THREE.MeshBasicMaterial({ map: tex });
                photoSphere = new THREE.Mesh(geometry, material);
                scene.add(photoSphere);
                return;
            }
            const u = (urls[idx] || '').replace('http://','https://');
            try {
                let texture;
                if (u.startsWith('data:')) {
                    texture = await new Promise((resolve, reject) => { textureLoader.load(u, resolve, undefined, reject); });
                } else if (window.createImageBitmap) {
                    texture = await loadTextureViaFetch(u);
                } else {
                    texture = await new Promise((resolve, reject) => { textureLoader.load(u, resolve, undefined, reject); });
                }
                const material = new THREE.MeshBasicMaterial({ map: texture });
                photoSphere = new THREE.Mesh(geometry, material);
                scene.add(photoSphere);
            } catch (e) {
                idx++;
                tryNext();
            }
        };
        tryNext();
document.getElementById('sol').textContent = photo.sol;
document.getElementById('camera').textContent = photo.camera.full_name || photo.camera.name;
document.getElementById('earthDate').textContent = photo.earth_date || '';
document.getElementById('totalPhotos').textContent = `${index + 1} / ${photos.length}`;
updateThumbnails();
}

function createThumbnails() {
const gallery = document.getElementById('photoGallery');
gallery.innerHTML = '';
photos.forEach((photo, index) => {
const img = document.createElement('img');
img.src = photo.img_src;
img.className = 'thumbnail';
if (index === 0) img.classList.add('active');
img.onclick = () => loadPhoto(index);
gallery.appendChild(img);
});
}

function updateThumbnails() {
const thumbnails = document.querySelectorAll('.thumbnail');
thumbnails.forEach((thumb, index) => { thumb.classList.toggle('active', index === currentPhotoIndex); });
}

function prevPhoto() { if (currentPhotoIndex > 0) { loadPhoto(currentPhotoIndex - 1); } }
function nextPhoto() { if (currentPhotoIndex < photos.length - 1) { loadPhoto(currentPhotoIndex + 1); } }

        function enableOrientation() {
            window.addEventListener('deviceorientation', handleOrientation);
            gyroEnabled = true;
            document.getElementById('gyroStatus').style.display = 'block';
            document.getElementById('gyroText').textContent = '✅ Active';
        }

        function enableGyro() {
            document.getElementById('gyroStatus').style.display = 'block';
            document.getElementById('gyroText').textContent = '⏳ Requesting permission';
            try {
                if (typeof DeviceOrientationEvent !== 'undefined' && typeof DeviceOrientationEvent.requestPermission === 'function') {
                    DeviceOrientationEvent.requestPermission().then(response => {
                        if (response === 'granted') { enableOrientation(); }
                        else {
                            if (typeof DeviceMotionEvent !== 'undefined' && typeof DeviceMotionEvent.requestPermission === 'function') {
                                DeviceMotionEvent.requestPermission().then(r => { if (r === 'granted') { enableOrientation(); } else { document.querySelector('#permissionGate .desc').textContent = 'İzin verilmedi'; document.getElementById('gyroText').textContent = '❌ Not granted'; } }).catch(() => { document.querySelector('#permissionGate .desc').textContent = 'İzin hatası'; document.getElementById('gyroText').textContent = '❌ Not granted'; });
                            } else {
                                document.querySelector('#permissionGate .desc').textContent = 'İzin verilmedi';
                                document.getElementById('gyroText').textContent = '❌ Not granted';
                            }
                        }
                    }).catch(() => { document.querySelector('#permissionGate .desc').textContent = 'İzin hatası'; document.getElementById('gyroText').textContent = '❌ Error'; });
                    return;
                }
            } catch (e) {}
            if (window.DeviceOrientationEvent) { enableOrientation(); }
            else { document.getElementById('gyroText').textContent = '❌ Unavailable'; }
        }

        function enableGyroAndHide() {
            enableGyro();
            document.getElementById('permissionGate').style.display = 'none';
        }

        function calibrateGyro() {
            if (!gyroEnabled) {
                document.getElementById('gyroStatus').style.display = 'block';
                document.getElementById('gyroText').textContent = 'ℹ️ Enable gyro first';
                return;
            }
            offAlpha = alpha;
            offBeta = beta;
            offGamma = gamma;
            document.getElementById('gyroText').textContent = '🎯 Calibrated';
        }

function zoomIn() {
    camera.fov = Math.max(50, Math.min(90, camera.fov - 2));
    camera.updateProjectionMatrix();
}

function zoomOut() {
    camera.fov = Math.max(50, Math.min(90, camera.fov + 2));
    camera.updateProjectionMatrix();
}

        function restartVR() {
            try {
                window.removeEventListener('deviceorientation', handleOrientation);
                gyroEnabled = false;
                sAlpha = 0; sBeta = 0; sGamma = 0;
                offAlpha = 0; offBeta = 0; offGamma = 0;
                camera.rotation.set(0, 0, 0);
                if (photoSphere) {
                    scene.remove(photoSphere);
                    try { photoSphere.geometry.dispose(); } catch(e) {}
                    try { photoSphere.material.dispose(); } catch(e) {}
                    photoSphere = null;
                }
                loadPhoto(currentPhotoIndex);
                document.getElementById('gyroStatus').style.display = 'block';
                document.getElementById('gyroText').textContent = '⏹️ Off';
            } catch (e) {}
        }

        function setupControls() {
            renderer.domElement.addEventListener('mousedown', (e) => { mouseDown = true; previousMouseX = e.clientX; previousMouseY = e.clientY; });
            renderer.domElement.addEventListener('mousemove', (e) => {
                if (mouseDown) {
                    const deltaX = e.clientX - previousMouseX;
                    const deltaY = e.clientY - previousMouseY;
                    camera.rotation.y -= deltaX * 0.002;
                    camera.rotation.x -= deltaY * 0.002;
                    camera.rotation.x = Math.max(-Math.PI / 2, Math.min(Math.PI / 2, camera.rotation.x));
                    previousMouseX = e.clientX;
                    previousMouseY = e.clientY;
                }
            });
            renderer.domElement.addEventListener('mouseup', () => { mouseDown = false; });
            let touchStartX = 0, touchStartY = 0;
        renderer.domElement.style.touchAction = 'none';
        renderer.domElement.addEventListener('touchstart', (e) => { if (e.touches.length === 1) { touchStartX = e.touches[0].clientX; touchStartY = e.touches[0].clientY; } });
            renderer.domElement.addEventListener('touchmove', (e) => {
        if (e.touches.length === 1 && !gyroEnabled) {
            const deltaX = e.touches[0].clientX - touchStartX;
            const deltaY = e.touches[0].clientY - touchStartY;
            camera.rotation.y -= deltaX * 0.002;
            camera.rotation.x -= deltaY * 0.002;
            camera.rotation.x = Math.max(-Math.PI / 2, Math.min(Math.PI / 2, camera.rotation.x));
            touchStartX = e.touches[0].clientX;
            touchStartY = e.touches[0].clientY;
        }
        if (e.touches.length === 2) {
            const dx = e.touches[0].clientX - e.touches[1].clientX;
            const dy = e.touches[0].clientY - e.touches[1].clientY;
            const dist = Math.sqrt(dx*dx + dy*dy);
            if (!window.__pinchStart) { window.__pinchStart = dist; window.__startFov = camera.fov; }
            const scale = dist / window.__pinchStart;
            camera.fov = Math.max(40, Math.min(100, window.__startFov / scale));
            camera.updateProjectionMatrix();
        }
            });
            renderer.domElement.addEventListener('touchend', () => { if (!gyroEnabled) { enableGyroAndHide(); } });
            renderer.domElement.addEventListener('click', () => { if (!gyroEnabled) { enableGyroAndHide(); } });
        if (window.DeviceOrientationEvent && typeof DeviceOrientationEvent.requestPermission !== 'function') {
            setTimeout(() => {
                window.addEventListener('deviceorientation', handleOrientation);
                gyroEnabled = true;
            }, 500);
        }
        }

        function handleOrientation(event) {
            if (!gyroEnabled) return;
            alpha = event.alpha || 0;
            beta = event.beta || 0;
            gamma = event.gamma || 0;
            sAlpha = sAlpha + SMOOTH * ((alpha - offAlpha) - sAlpha);
            sBeta  = sBeta  + SMOOTH * ((beta  - offBeta ) - sBeta);
            sGamma = sGamma + SMOOTH * ((gamma - offGamma) - sGamma);
            const alphaRad = sAlpha * (Math.PI / 180);
            const betaRad  = sBeta  * (Math.PI / 180);
            const gammaRad = sGamma * (Math.PI / 180);
    camera.rotation.set(-betaRad, alphaRad, 0, 'YXZ');
        }

        function nativeOrientationUpdate(a, b, g) {
            gyroEnabled = true;
            alpha = a || 0; beta = b || 0; gamma = g || 0;
            sAlpha = sAlpha + SMOOTH * ((alpha - offAlpha) - sAlpha);
            sBeta  = sBeta  + SMOOTH * ((beta  - offBeta ) - sBeta);
            sGamma = sGamma + SMOOTH * ((gamma - offGamma) - sGamma);
            const alphaRad = sAlpha * (Math.PI / 180);
            const betaRad  = sBeta  * (Math.PI / 180);
            const gammaRad = sGamma * (Math.PI / 180);
    camera.rotation.set(-betaRad, alphaRad, 0, 'YXZ');
            document.getElementById('gyroStatus').style.display = 'block';
            document.getElementById('gyroText').textContent = '✅ Active (Native)';
        }

function animate() { requestAnimationFrame(animate); renderer.render(scene, camera); }
init();
</script>
</body>
</html>
"""
    
    init(startGyroVR: Bool = false) {
        _showGyroVR = State(initialValue: startGyroVR)
    }
    
    var body: some View {
        GyroWebView(html: nil, urlString: "https://eyes.nasa.gov/apps/solar-system/#/mars")
            .ignoresSafeArea()
    }
    
    private var gyroHTMLResolved: String {
        let plistKey = Bundle.main.object(forInfoDictionaryKey: "NASA_API_KEY") as? String
        let envKey = ProcessInfo.processInfo.environment["NASA_API_KEY"]
        let apiKey = (plistKey?.isEmpty == false ? plistKey : nil) ?? (envKey?.isEmpty == false ? envKey : nil) ?? "DEMO_KEY"
        return gyroHTML.replacingOccurrences(of: "DEMO_KEY", with: apiKey)
    }
    
    private func embedTextureIntoHTML() async {
        // Önce uygulama belgelerinde kalıcı yerel dosya var mı bak
        if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let localURL = docs.appendingPathComponent("mars_1024.jpg")
            if FileManager.default.fileExists(atPath: localURL.path) {
                do {
                    let data = try Data(contentsOf: localURL)
                    let base64 = data.base64EncodedString()
                    let dataURL = "data:image/jpeg;base64,\(base64)"
                    await MainActor.run { injectedHTML = gyroHTMLResolved.replacingOccurrences(of: "MARS_TEXTURE", with: dataURL) }
                    return
                } catch { }
            }
        }
        // Sonra yerel bundle içinde dosya var mı bak
        let localNames = [
            ("mars_1024", "jpg"),
            ("mars", "jpg"),
            ("mars_1024", "png"),
            ("mars", "png")
        ]
        for (name, ext) in localNames {
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                do {
                    let data = try Data(contentsOf: url)
                    let base64 = data.base64EncodedString()
                    let dataURL = "data:image/\(ext);base64,\(base64)"
                    await MainActor.run { injectedHTML = gyroHTMLResolved.replacingOccurrences(of: "MARS_TEXTURE", with: dataURL) }
                    return
                } catch { }
            }
        }
        // Yerel yoksa uzaktan dene ve indirip uygulama belgelerine kaydet
        let candidates = [
            "https://unpkg.com/three@0.128.0/examples/textures/planets/mars_1024.jpg",
            "https://cdn.jsdelivr.net/gh/mrdoob/three.js@r128/examples/textures/planets/mars_1024.jpg",
            "https://raw.githubusercontent.com/mrdoob/three.js/r128/examples/textures/planets/mars_1024.jpg",
            "https://threejs.org/examples/textures/planets/mars_1024.jpg"
        ]
        for u in candidates {
            guard let url = URL(string: u.replacingOccurrences(of: "http://", with: "https://")) else { continue }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    let localURL = docs.appendingPathComponent("mars_1024.jpg")
                    try? data.write(to: localURL, options: .atomic)
                }
                let base64 = data.base64EncodedString()
                let dataURL = "data:image/jpeg;base64,\(base64)"
                await MainActor.run { injectedHTML = gyroHTMLResolved.replacingOccurrences(of: "MARS_TEXTURE", with: dataURL) }
                return
            } catch {
                continue
            }
        }
        await MainActor.run { injectedHTML = gyroHTMLResolved.replacingOccurrences(of: "MARS_TEXTURE", with: "") }
    }
    
    func loadLatestPhotos() async {
        let rover = selectedRover.rawValue.lowercased()
        let plistKey = Bundle.main.object(forInfoDictionaryKey: "NASA_API_KEY") as? String
        let envKey = ProcessInfo.processInfo.environment["NASA_API_KEY"]
        let apiKey = (plistKey?.isEmpty == false ? plistKey : nil) ?? (envKey?.isEmpty == false ? envKey : nil) ?? "DEMO_KEY"
        let urlString = "https://api.nasa.gov/mars-photos/api/v1/rovers/\(rover)/latest_photos?api_key=\(apiKey)"
        guard let url = URL(string: urlString) else { await MainActor.run { self.photos = RoverPhoto.samples(for: selectedRover) }; return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(LatestPhotosResponse.self, from: data)
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            df.locale = Locale(identifier: "en_US_POSIX")
            let list = decoded.latest_photos.map { p in
                RoverPhoto(sol: p.sol, earthDate: df.date(from: p.earth_date) ?? Date(), camera: p.camera.name, imageURL: p.img_src.replacingOccurrences(of: "http://", with: "https://"))
            }
            await MainActor.run { self.photos = list }
        } catch {
            await MainActor.run { self.photos = RoverPhoto.samples(for: selectedRover) }
        }
    }
}

struct GyroWebView: UIViewRepresentable {
    let html: String?
    let urlString: String?
    class Coordinator: NSObject, WKNavigationDelegate {
        let motion = CMMotionManager()
        weak var webView: WKWebView?
        func startMotion() {
            guard motion.isDeviceMotionAvailable else { return }
            motion.deviceMotionUpdateInterval = 1.0 / 60.0
            motion.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { [weak self] motionData, _ in
                guard let self = self, let m = motionData, let wv = self.webView else { return }
                let yaw = m.attitude.yaw * 180.0 / .pi
                let pitch = m.attitude.pitch * 180.0 / .pi
                let roll = m.attitude.roll * 180.0 / .pi
                let js = "nativeOrientationUpdate(\(yaw),\(pitch),\(roll));"
                wv.evaluateJavaScript(js, completionHandler: nil)
            }
        }
        deinit { motion.stopDeviceMotionUpdates() }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            self.webView = webView
        }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.allowsInlineMediaPlayback = true
        let ucc = WKUserContentController()
        let js = """
        (function(){
          const css = `
          header, nav, [role="banner"], .header, .top-bar, .eyes-header, .app-header { display:none !important; }
          a[href*="eyes.nasa.gov" i] { display:none !important; }
          img[alt*="NASA" i], svg[aria-label*="NASA" i], [title*="NASA" i] { display:none !important; }
          `;
          function inject(){
            if (!document.head) return;
            var style = document.head.querySelector('style[data-hide-brand="1"]');
            if (!style) { style = document.createElement('style'); style.setAttribute('data-hide-brand','1'); style.innerHTML = css; document.head.appendChild(style); }
            function baseHide(){
              document.querySelectorAll('img[alt*="NASA" i], svg[aria-label*="NASA" i], [title*="NASA" i], a[href*="eyes.nasa.gov" i]').forEach(el=>{ el.style.display='none'; });
              const texts = ['eyes on the solar system','eyes.nasa.gov'];
              const all = document.querySelectorAll('h1,h2,h3,div,span,button,a');
              all.forEach(el=>{
                const t=(el.textContent||'').trim().toLowerCase();
                if (t && t.length < 120 && texts.some(x=>t.includes(x))) { el.style.display='none'; }
              });
            }
            function earthHide(){
              const earthTexts = ['visible earth','latest event','observed','home','mars','earth now','passes','live'];
              const nodes = document.querySelectorAll('*');
              nodes.forEach(el=>{
                const t=(el.textContent||'').toLowerCase();
                if (t && earthTexts.some(x=>t.includes(x))) { el.style.display='none'; }
              });
              document.querySelectorAll('[aria-label*="Back" i],[aria-label*="Menu" i],[aria-label*="Home" i]').forEach(el=>{ el.style.display='none'; });
              const fixeds = Array.from(document.querySelectorAll('*')).filter(el=>{
                const st=getComputedStyle(el);
                return st.position==='fixed' && (st.top==='0px' || st.bottom==='0px') && el.tagName.toLowerCase()!=='canvas';
              });
              fixeds.forEach(el=>{ el.style.display='none'; });
              const c=document.querySelector('canvas');
              if(c){ c.style.position='fixed'; c.style.top='0'; c.style.left='0'; c.style.width='100vw'; c.style.height='100vh'; c.style.zIndex='1'; }
              document.documentElement.style.overflow='hidden';
              document.body.style.background='#000';
              document.documentElement.style.background='#000';
            }
            function hide(){
              const isEarth = location.href.toLowerCase().includes('/apps/earth');
              if (isEarth) {
                try {
                  document.querySelectorAll('*').forEach(el=>{
                    const txt=(el.textContent||'').trim();
                    const aria=(el.getAttribute('aria-label')||'').toLowerCase();
                    if (txt==='+' || aria.includes('add') || aria.includes('plus')) { el.style.display='none'; }
                  });
                  const labels = Array.from(document.querySelectorAll('*')).filter(el=>((el.textContent||'').toLowerCase().includes('visible earth')));
                  labels.forEach(lbl=>{
                    const p = lbl.parentElement;
                    if (!p) return;
                    p.querySelectorAll('button,a,span,div').forEach(ch=>{ const ct=(ch.textContent||'').trim(); if (ct==='+') { ch.style.display='none'; } });
                  });
                } catch(e) {}
              } else {
                baseHide();
              }
            }
            hide();
            new MutationObserver(hide).observe(document.documentElement,{childList:true,subtree:true});
          }
          if (document.readyState==='loading') document.addEventListener('DOMContentLoaded',inject); else inject();
        })();
        """
        let script = WKUserScript(source: js, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        ucc.addUserScript(script)
        config.userContentController = ucc
        let webview = WKWebView(frame: .zero, configuration: config)
        webview.isOpaque = true
        webview.backgroundColor = .black
        webview.navigationDelegate = context.coordinator
        return webview
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let s = urlString, let url = URL(string: s) {
            uiView.load(URLRequest(url: url))
        } else {
            uiView.loadHTMLString(html ?? "", baseURL: nil)
        }
    }
}

struct SafariWebView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController { SFSafariViewController(url: url) }
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

struct SolarSystemEyesView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        ZStack(alignment: .topLeading) {
            GyroWebView(html: nil, urlString: "https://eyes.nasa.gov/apps/solar-system/#/home")
                .ignoresSafeArea()
            Button { dismiss() } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.4), radius: 4, x: 0, y: 2)
            }
            .padding(.top, 16)
            .padding(.leading, 16)
        }
    }
}

struct MarsEyesView: View {
    var body: some View {
        GyroWebView(html: nil, urlString: "https://eyes.nasa.gov/apps/solar-system/#/mars")
            .ignoresSafeArea()
    }
}

struct RoverStatusCard: View {
    let rover: MarsRover
    
    var body: some View {
        VStack(spacing: 15) {
            
            Text(rover.rawValue)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Status Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                StatusBadge(icon: "📅", label: "Sol", value: "\(rover.sol)")
                StatusBadge(icon: "📏", label: "Distance", value: rover.distance)
                StatusBadge(icon: "🔋", label: "Power", value: rover.batteryLevel)
                StatusBadge(icon: "📡", label: "Comm", value: rover.commStatus)
            }
            
            // Active Status
            HStack {
                Circle()
                    .fill(rover.isActive ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                Text(rover.isActive ? "Active" : "Inactive")
                    .foregroundColor(rover.isActive ? .green : .red)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(15)
    }
}

struct StatusBadge: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 5) {
            Text(icon)
                .font(.title3)
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.cyan)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.3))
        .cornerRadius(10)
    }
}

struct RoverPhotoCard: View {
    let photo: RoverPhoto
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Placeholder Image
            ZStack {
                Color.gray.opacity(0.2)
                AsyncImage(url: URL(string: photo.imageURL)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .tint(.white)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        VStack {
                            Image(systemName: "photo.fill")
                                .font(.title)
                                .foregroundColor(.white.opacity(0.5))
                            Text(photo.camera)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            .frame(height: 150)
            .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 3) {
                Text("Sol \(photo.sol)")
                    .font(.caption)
                    .foregroundColor(.cyan)
                
                Text(photo.earthDate, style: .date)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

struct MissionInfoSection: View {
    let rover: MarsRover
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ℹ️ Mission Info")
                .font(.headline)
                .foregroundColor(.white)
            
            InfoRow(label: "Launch", value: rover.launchDate)
            InfoRow(label: "Landing", value: rover.landingDate)
            InfoRow(label: "Mission Duration", value: rover.missionDuration)
            InfoRow(label: "Mass", value: rover.mass)
            
            Divider()
            
            Text(rover.description)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(15)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .foregroundColor(.white)
        }
        .font(.caption)
    }
}

// MARK: - Models

enum MarsRover: String, CaseIterable {
    case perseverance = "Perseverance"
    case curiosity = "Curiosity"
    case opportunity = "Opportunity"
    case spirit = "Spirit"
    
    var icon: String {
        ""
    }
    
    var sol: Int {
        switch self {
        case .perseverance: return 1000
        case .curiosity: return 4050
        case .opportunity: return 5352
        case .spirit: return 2208
        }
    }
    
    var distance: String {
        switch self {
        case .perseverance: return "23.1 km"
        case .curiosity: return "31.4 km"
        case .opportunity: return "45.2 km"
        case .spirit: return "7.7 km"
        }
    }
    
    var batteryLevel: String {
        switch self {
        case .perseverance: return "92%"
        case .curiosity: return "85%"
        case .opportunity: return "0%"
        case .spirit: return "0%"
        }
    }
    
    var commStatus: String {
        switch self {
        case .perseverance, .curiosity: return "Good"
        case .opportunity, .spirit: return "Lost"
        }
    }
    
    var isActive: Bool {
        switch self {
        case .perseverance, .curiosity: return true
        case .opportunity, .spirit: return false
        }
    }
    
    var launchDate: String {
        switch self {
        case .perseverance: return "30 July 2020"
        case .curiosity: return "26 November 2011"
        case .opportunity: return "7 July 2003"
        case .spirit: return "10 June 2003"
        }
    }
    
    var landingDate: String {
        switch self {
        case .perseverance: return "18 February 2021"
        case .curiosity: return "6 August 2012"
        case .opportunity: return "25 January 2004"
        case .spirit: return "4 January 2004"
        }
    }
    
    var missionDuration: String {
        switch self {
        case .perseverance: return "~4 years (ongoing)"
        case .curiosity: return "~13 years (ongoing)"
        case .opportunity: return "15 years (2004–2019)"
        case .spirit: return "6 years (2004–2010)"
        }
    }
    
    var mass: String {
        switch self {
        case .perseverance: return "1,025 kg"
        case .curiosity: return "899 kg"
        case .opportunity, .spirit: return "185 kg"
        }
    }
    
    var description: String {
        switch self {
        case .perseverance:
            return "The most advanced rover searching for signs of past life on Mars. Works with the Ingenuity helicopter."
        case .curiosity:
            return "Exploring Mars' past in Gale Crater. Still actively operating."
        case .opportunity:
            return "Operated 60 times longer than its planned 90-day mission. Lost in a dust storm in 2019."
        case .spirit:
            return "Opportunity's twin. Stuck in sand; communication ended in 2010."
        }
    }
}

struct RoverStatus {
    let sol: Int
    let earthDate: Date
    let batteryLevel: Int
    let temperature: Double
}

struct RoverPhoto: Identifiable {
    let id = UUID()
    let sol: Int
    let earthDate: Date
    let camera: String
    let imageURL: String
    
    static func samples(for rover: MarsRover) -> [RoverPhoto] {
        let dates = (0..<6).map { Date().addingTimeInterval(-Double($0) * 86400) }
        let cameras = ["NAVCAM", "MASTCAM", "FHAZ", "RHAZ", "CHEMCAM", "MAHLI"]
        let urls: [String]
        switch rover {
        case .perseverance:
            urls = [
                "https://images-assets.nasa.gov/image/PIA24265/PIA24265~orig.jpg",
                "https://images-assets.nasa.gov/image/PIA24426/PIA24426~orig.jpg",
                "https://images-assets.nasa.gov/image/PIA24428/PIA24428~orig.jpg",
                "https://images-assets.nasa.gov/image/PIA24645/PIA24645~orig.jpg",
                "https://images-assets.nasa.gov/image/PIA24546/PIA24546~orig.jpg",
                "https://images-assets.nasa.gov/image/PIA24264/PIA24264~orig.jpg"
            ]
        case .curiosity:
            urls = [
                "https://images-assets.nasa.gov/image/PIA16802/PIA16802~orig.jpg",
                "https://images-assets.nasa.gov/image/PIA16239/PIA16239~orig.jpg",
                "https://images-assets.nasa.gov/image/PIA16764/PIA16764~orig.jpg",
                "https://images-assets.nasa.gov/image/PIA17652/PIA17652~orig.jpg",
                "https://images-assets.nasa.gov/image/PIA17385/PIA17385~orig.jpg",
                "https://images-assets.nasa.gov/image/PIA16803/PIA16803~orig.jpg"
            ]
        case .opportunity:
            urls = [
                "https://images-assets.nasa.gov/image/PIA17563/PIA17563~orig.jpg",
                "https://images-assets.nasa.gov/image/PIA14085/PIA14085~orig.jpg",
                "https://images-assets.nasa.gov/image/PIA10214/PIA10214~orig.jpg",
                "https://images-assets.nasa.gov/image/PIA07997/PIA07997~orig.jpg",
                "https://images-assets.nasa.gov/image/PIA10215/PIA10215~orig.jpg",
                "https://images-assets.nasa.gov/image/PIA17562/PIA17562~orig.jpg"
            ]
        case .spirit:
            urls = [
                "https://images-assets.nasa.gov/image/PIA05003/PIA05003~orig.jpg",
                "https://images-assets.nasa.gov/image/PIA05005/PIA05005~orig.jpg",
                "https://images-assets.nasa.gov/image/PIA05006/PIA05006~orig.jpg",
                "https://images-assets.nasa.gov/image/PIA05008/PIA05008~orig.jpg",
                "https://images-assets.nasa.gov/image/PIA05004/PIA05004~orig.jpg",
                "https://images-assets.nasa.gov/image/PIA05007/PIA05007~orig.jpg"
            ]
        }
        return (0..<6).map { index in
            RoverPhoto(
                sol: rover.sol - index,
                earthDate: dates[index],
                camera: cameras[index],
                imageURL: urls[index]
            )
        }
    }
}

struct LatestPhotosResponse: Codable {
    struct Photo: Codable {
        let id: Int
        let sol: Int
        let camera: Camera
        let img_src: String
        let earth_date: String
        struct Camera: Codable { let name: String }
    }
    let latest_photos: [Photo]
}

struct RoverPhotoDetailView: View {
    let photo: RoverPhoto
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                AsyncImage(url: URL(string: photo.imageURL)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView().tint(.white)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(scale)
                            .offset(offset)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        let delta = value / lastScale
                                        let newScale = (scale * delta).clamped(to: 1...4)
                                        scale = newScale
                                        lastScale = value
                                    }
                                    .onEnded { _ in
                                        lastScale = 1.0
                                    }
                            )
                            .gesture(
                                DragGesture()
                                    .onChanged { g in
                                        offset = CGSize(width: lastOffset.width + g.translation.width, height: lastOffset.height + g.translation.height)
                                    }
                                    .onEnded { _ in
                                        lastOffset = offset
                                    }
                            )
                    case .failure:
                        Image(systemName: "photo.fill").foregroundColor(.white.opacity(0.6))
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "xmark.circle.fill").foregroundColor(.white) }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let url = URL(string: photo.imageURL) {
                        ShareLink(item: url) { Image(systemName: "square.and.arrow.up").foregroundColor(.white) }
                    }
                }
            }
        }
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self { min(max(self, range.lowerBound), range.upperBound) }
}

#Preview {
    MarsRoverView()
}
