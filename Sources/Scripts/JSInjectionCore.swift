import Foundation

class JSInjectionCore {
    static let zapperScript = """
        window._zapperSetup = true;
        document.addEventListener('mouseover', e => { 
            if(window._isZapping) { 
                e.target.setAttribute('data-zap-old-outline', e.target.style.outline || ''); 
                e.target.style.setProperty('outline', '3px solid #ff4444', 'important'); 
                e.target.style.setProperty('cursor', 'crosshair', 'important'); 
            } 
        }, true);
        document.addEventListener('mouseout', e => { 
            if(window._isZapping) { 
                e.target.style.outline = e.target.getAttribute('data-zap-old-outline') || ''; 
            } 
        }, true);
        document.addEventListener('click', e => { 
            if(window._isZapping) { 
                e.preventDefault(); e.stopPropagation(); e.stopImmediatePropagation();
                e.target.style.outline = e.target.getAttribute('data-zap-old-outline') || ''; 
                e.target.style.setProperty('display', 'none', 'important'); 
                window._isZapping = false; 
                if(window.webkit && window.webkit.messageHandlers.zapComplete) {
                    window.webkit.messageHandlers.zapComplete.postMessage('Done');
                }
            } 
        }, true);
    """
    
    static let scriptletsCore = """
        // 1. window.open-defuser (Generic popup blocker)
        const _orion_open = window.open;
        window.open = function(url, windowName, windowFeatures) {
            // Very strict popup block on known ad-heavy domains
            if (window.location.hostname.includes('rezka.ag') || window.location.hostname.includes('hdrezka') || window.location.hostname.includes('twitch.tv')) {
                // Allow internal popups (like the popup video player) or empty initializing popups
                if (!url || typeof url !== 'string' || url === '' || url.includes(window.location.hostname) || url.startsWith('/') || url.startsWith('about:blank')) {
                    console.log('Orion: Allowed internal popup to ' + url);
                    return _orion_open.apply(this, arguments);
                }
                console.log('Orion: Blocked Ad-Popup to ' + url);
                return null;
            }
            return _orion_open.apply(this, arguments);
        };

        // 1.5 Global Scrollbar Hider
        var globalStyle = document.createElement('style');
        globalStyle.innerHTML = '::-webkit-scrollbar { display: none !important; width: 0 !important; height: 0 !important; }';
        if (document.documentElement) document.documentElement.appendChild(globalStyle);

        // 1.6 In-App Fullscreen Polyfill
        Object.defineProperty(document, 'fullscreenEnabled', { get: () => true, configurable: true });
        Object.defineProperty(document, 'webkitFullscreenEnabled', { get: () => true, configurable: true });
        
        let _orion_fsEl = null; let _orion_oldFSStyles = {};
        const _orion_enterFS = function() {
            _orion_fsEl = this;
            _orion_oldFSStyles = { position: this.style.position, top: this.style.top, left: this.style.left, width: this.style.width, height: this.style.height, zIndex: this.style.zIndex, backgroundColor: this.style.backgroundColor };
            this.style.setProperty('position', 'fixed', 'important');
            this.style.setProperty('top', '0', 'important');
            this.style.setProperty('left', '0', 'important');
            this.style.setProperty('width', '100vw', 'important');
            this.style.setProperty('height', '100vh', 'important');
            this.style.setProperty('z-index', '2147483647', 'important');
            this.style.setProperty('background-color', 'black', 'important');
            Object.defineProperty(document, 'fullscreenElement', { get: () => this, configurable: true });
            Object.defineProperty(document, 'webkitFullscreenElement', { get: () => this, configurable: true });
            this.dispatchEvent(new Event('fullscreenchange', { bubbles: true }));
            this.dispatchEvent(new Event('webkitfullscreenchange', { bubbles: true }));
            return Promise.resolve();
        };
        const _orion_exitFS = function() {
            if(_orion_fsEl) {
                _orion_fsEl.style.position = _orion_oldFSStyles.position || '';
                _orion_fsEl.style.top = _orion_oldFSStyles.top || '';
                _orion_fsEl.style.left = _orion_oldFSStyles.left || '';
                _orion_fsEl.style.width = _orion_oldFSStyles.width || '';
                _orion_fsEl.style.height = _orion_oldFSStyles.height || '';
                _orion_fsEl.style.zIndex = _orion_oldFSStyles.zIndex || '';
                _orion_fsEl.style.backgroundColor = _orion_oldFSStyles.backgroundColor || '';
                _orion_fsEl = null;
            }
            Object.defineProperty(document, 'fullscreenElement', { get: () => null, configurable: true });
            Object.defineProperty(document, 'webkitFullscreenElement', { get: () => null, configurable: true });
            document.dispatchEvent(new Event('fullscreenchange', { bubbles: true }));
            document.dispatchEvent(new Event('webkitfullscreenchange', { bubbles: true }));
            return Promise.resolve();
        };
        Element.prototype.requestFullscreen = _orion_enterFS;
        Element.prototype.webkitRequestFullscreen = _orion_enterFS;
        document.exitFullscreen = _orion_exitFS;
        document.webkitExitFullscreen = _orion_exitFS;

        // 2. RuAdList implementation for HD Rezka
        if (window.location.hostname.includes('rezka.ag') || window.location.hostname.includes('hdrezka')) {
            var style = document.createElement('style');
            style.innerHTML = `
                html, body {
                    background-image: none !important; 
                    background-color: #1a1a1a !important; 
                }
                .b-top-banner, .b-side-banner, .b-bottom-banner, .b-post__promoblock, .promoblock, .b-wrapper_banners,
                [class*="banner"], [id*="banner"], [id^="bn_"],
                div[style*="position: fixed"][style*="bottom"],
                a[href*="t.me/"] > img,
                a[href*="1xbet"], a[href*="casino"], a[href*="bet"], a[href*="win"], a[href*="bonus"],
                a[target="_blank"] > img[src*="gif"] { 
                    display: none !important; pointer-events: none !important; opacity: 0 !important; width: 0 !important; height: 0 !important;
                }
            `;
            if (document.documentElement) document.documentElement.appendChild(style);
        }
        
        // 3. Twitch Scriptlets
        if (window.location.hostname.includes('twitch.tv')) {
            const style = document.createElement('style');
            style.innerHTML = `
                [data-a-target="top-nav-more-button"],
                button[aria-label="More"],
                button[aria-label="Больше"],
                button[aria-label="Más"],
                [data-test-selector="sda-wrapper"] {
                    display: none !important;
                }
            `;
            if (document.documentElement) document.documentElement.appendChild(style);
            
            const _origPlay = HTMLMediaElement.prototype.play;
            HTMLMediaElement.prototype.play = function() {
                let isTwitchHome = window.location.hostname.includes('twitch.tv') && window.location.pathname === '/';
                
                if (isTwitchHome && !window._orionPlayOverride) {
                    this.pause(); 
                    return Promise.resolve();
                }
                
                const promise = _origPlay.apply(this, arguments);
                if (promise) promise.catch(err => { if (err.name === 'NotAllowedError') {} });
                return promise || Promise.resolve();
            };
            
            window.addEventListener('mousedown', (e) => {
                if (e.target.closest('[data-a-target="player-play-pause-button"]') || e.target.closest('.player-controls__left-control-group')) {
                    window._orionPlayOverride = true;
                    setTimeout(() => window._orionPlayOverride = false, 1500);
                }
            }, true);
        }
    """
}
