final index = '''
<!doctype html><html lang="en"><head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/><title>Loading...</title><style>:root {
            --primary-blue: rgb(46, 55, 103);
            --bg: #f8fafc;
            --text: #0f172a;
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            font-family: Arial, sans-serif;
        }

        body {
            min-height: 100vh;
            display: grid;
            place-items: center;
            background: var(--bg);
            color: var(--text);
        }

        .loading-container {
            text-align: center;
            width: 300px;
        }


        .spinner {
            width: 56px;
            height: 56px;
            border: 6px solid #dbeafe;
            border-top-color: var(--primary-blue);
            border-radius: 50%;
            margin: 0 auto 16px;
            animation: spin 0.9s linear infinite;
        }

        .loading-text {
            font-size: 1rem;
            color: var(--primary-blue);
            letter-spacing: 0.4px;
            margin-top: 20px;
            margin-bottom: 20px;
        }

        .loading-text a {
            font-size: 1rem;
            color: var(--primary-blue);
            letter-spacing: 0.4px;
            margin-top: 20px;
            margin-bottom: 20px;
        }

        @keyframes spin {
            to { transform: rotate(360deg); }
        }</style><script type="module">/******/ var __webpack_modules__ = ({

/***/ "./src/load-manager.ts"
(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   LoadManager: () => (/* binding */ LoadManager)
/* harmony export */ });
/* harmony import */ var _util__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__("./src/util.ts");

class LoadManager {
    _time = 0;
    _busyCount = 0;
    _expCallTime = 1000;
    step = 0;
    period = 1000;
    setRate(v) {
        this._expCallTime = v * this.period;
    }
    timeBegin() {
        this._time = performance.now();
    }
    timeEnd() {
        const t = performance.now() - this._time;
        this._time = Math.max(t, 0.1);
    }
    idle() {
        // update step
        const stepPerMs = this.step / this._time;
        // console.log(
        //   'step:', this.step,
        //   'time:', this._time,
        //   'stepPerMs:',stepPerMs,
        //   'expCallTime',this._expCallTime
        // )
        this.step = Math.ceil(stepPerMs * this._expCallTime);
        const remain = this.period - this._time;
        if (remain > 0) {
            this._busyCount = 0;
            return (0,_util__WEBPACK_IMPORTED_MODULE_0__.sleep)(remain);
        }
        if (++this._busyCount > 5) {
            this._busyCount = 0;
            return (0,_util__WEBPACK_IMPORTED_MODULE_0__.sleep)(0);
        }
        // no sleep (sync)
    }
}


/***/ },

/***/ "./src/util.ts"
(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   bswap: () => (/* binding */ bswap),
/* harmony export */   fillTmpl: () => (/* binding */ fillTmpl),
/* harmony export */   randU32: () => (/* binding */ randU32),
/* harmony export */   sleep: () => (/* binding */ sleep)
/* harmony export */ });
function sleep(ms) {
    return new Promise(fn => {
        setTimeout(fn, ms);
    });
}
function randU32() {
    return Math.random() * 0xFFFFFFFF >>> 0;
}
function bswap(n) {
    return (((n & 0x0000FF) << 24) |
        ((n & 0x00FF00) << 8) |
        ((n & 0xFF0000) >> 8) |
        (n >>> 24)) >>> 0;
}
function fillTmpl(tmpl, params) {
    // glsl is embedded in base64 to avoid issue with dart templating
    return atob(tmpl).replace(/__(\\w+)__/g, (_, \$1) => {
        return params[\$1] + '';
    });
}


/***/ },

/***/ "./src/webgl2.ts"
(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   init: () => (/* binding */ init),
/* harmony export */   setLoadRate: () => (/* binding */ setLoadRate),
/* harmony export */   start: () => (/* binding */ start),
/* harmony export */   stop: () => (/* binding */ stop)
/* harmony export */ });
/* harmony import */ var _assets_webgl2_b64_glsl__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__("./src/assets/webgl2.b64.glsl");
/* harmony import */ var _util__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__("./src/util.ts");
/* harmony import */ var _load_manager__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__("./src/load-manager.ts");



const MAGIC_CODE = 0x19260817;
const texW = 1024;
const texH = 1024;
const thread = texW * texH;
let events;
let isRunning;
const loadmgr = new _load_manager__WEBPACK_IMPORTED_MODULE_2__.LoadManager();
loadmgr.period = 200;
function createWebGl() {
    const canvas = new OffscreenCanvas(texW, texH);
    const ctx = canvas.getContext('webgl2', {
        powerPreference: 'high-performance',
    });
    return { canvas, ctx };
}
function init(handler) {
    events = handler;
    const { ctx } = createWebGl();
    return !!ctx;
}
async function start(words, masks) {
    try {
        await startImpl(words, masks);
    }
    catch (err) {
        events.onError(err);
    }
    isRunning = false;
}
async function startImpl(words, masks) {
    const { canvas, ctx: gl } = createWebGl();
    if (!gl) {
        throw Error('webgl error');
    }
    loadmgr.step = 128;
    isRunning = true;
    canvas.addEventListener('webglcontextlost', () => {
        isRunning = false;
        events.onError(Error('webgl contextlost'));
    });
    // setTimeout(() => {
    //   console.log('mock contextlost')
    //   gl.getExtension("WEBGL_lose_context")!.loseContext()
    // }, 3000)
    const vertexData = new Float32Array([
        -1, +1, // left top
        -1, -1, // left bottom
        +1, +1, // right top
        +1, -1, // right bottom
    ]);
    gl.bindBuffer(34962 /* GL.ARRAY_BUFFER */, gl.createBuffer());
    gl.bufferData(34962 /* GL.ARRAY_BUFFER */, vertexData, 35044 /* GL.STATIC_DRAW */);
    const program = gl.createProgram();
    const VERTEX_SHADER = `\\
#version 300 es
in vec2 v_pos;
void main() {
gl_Position = vec4(v_pos, 0., 1.);
}`;
    const vertexShader = createShader(gl, VERTEX_SHADER, 35633 /* GL.VERTEX_SHADER */);
    const w4 = (0,_util__WEBPACK_IMPORTED_MODULE_1__.randU32)();
    const code = (0,_util__WEBPACK_IMPORTED_MODULE_1__.fillTmpl)(_assets_webgl2_b64_glsl__WEBPACK_IMPORTED_MODULE_0__, {
        'TEX_W': texW,
        'W0': words[0],
        'W1': words[1],
        'W2': words[2],
        'W3': words[3],
        'W4': w4,
        'MASK0': masks[0],
        'MASK1': masks[1],
        'MAGIC_CODE': MAGIC_CODE,
    });
    // console.log(code)
    const fragShader = createShader(gl, code, 35632 /* GL.FRAGMENT_SHADER */);
    // const dbg = gl.getExtension('WEBGL_debug_shaders')
    // if (dbg) {
    //   const s = dbg.getTranslatedShaderSource(fragShader)
    //   console.log(s)
    // } else {
    //   console.warn('WEBGL_debug_shaders not available')
    // }
    gl.attachShader(program, fragShader);
    gl.attachShader(program, vertexShader);
    await (0,_util__WEBPACK_IMPORTED_MODULE_1__.sleep)(0);
    gl.linkProgram(program);
    gl.useProgram(program);
    const posHandle = 0;
    gl.vertexAttribPointer(posHandle, 2 /*vec2*/, 5126 /* GL.FLOAT */, false, 0, 0);
    gl.enableVertexAttribArray(posHandle);
    const fbo = gl.createFramebuffer();
    const tex = gl.createTexture();
    gl.bindTexture(3553 /* GL.TEXTURE_2D */, tex);
    gl.texStorage2D(3553 /* GL.TEXTURE_2D */, 1, 36208 /* GL.RGBA32UI */, texW, texH);
    gl.bindFramebuffer(36160 /* GL.FRAMEBUFFER */, fbo);
    gl.framebufferTexture2D(36160 /* GL.FRAMEBUFFER */, 36064 /* GL.COLOR_ATTACHMENT0 */, 3553 /* GL.TEXTURE_2D */, tex, 0);
    // gl.disable(GL.DEPTH_TEST)
    // gl.disable(GL.STENCIL_TEST)
    // gl.depthMask(false)
    // gl.disable(GL.CULL_FACE)
    // gl.disable(GL.BLEND)
    const inStep = gl.getUniformLocation(program, 'in_step');
    const inW5 = gl.getUniformLocation(program, 'in_w5');
    const query = gl.createQuery();
    LOOP: for (let w5 = 0; w5 < 0xFFFFFFFF; w5++) {
        gl.beginQuery(35887 /* GL.ANY_SAMPLES_PASSED */, query);
        gl.uniform1ui(inW5, w5);
        gl.uniform1ui(inStep, loadmgr.step);
        gl.drawArrays(5 /* GL.TRIANGLE_STRIP */, 0, 4);
        gl.endQuery(35887 /* GL.ANY_SAMPLES_PASSED */);
        loadmgr.timeBegin();
        for (;;) {
            await (0,_util__WEBPACK_IMPORTED_MODULE_1__.sleep)(5);
            if (!isRunning) {
                break LOOP;
            }
            const done = gl.getQueryParameter(query, 34919 /* GL.QUERY_RESULT_AVAILABLE */);
            if (done) {
                break;
            }
        }
        loadmgr.timeEnd();
        const found = gl.getQueryParameter(query, 34918 /* GL.QUERY_RESULT */);
        if (found) {
            const arr = new Uint32Array(thread * 4);
            gl.readPixels(0, 0, texW, texH, 36249 /* GL.RGBA_INTEGER */, 5125 /* GL.UNSIGNED_INT */, arr);
            const index = arr.indexOf(MAGIC_CODE);
            console.assert(index >= 0, 'webgl error');
            const w6 = arr[index + 1];
            const w7 = arr[index + 2];
            const nonce = Uint32Array.of(w4, w5, w6, w7);
            events.onComplete(nonce);
            break;
        }
        events.onProgress(thread * loadmgr.step);
        await loadmgr.idle();
    }
}
function stop() {
    isRunning = false;
}
function setLoadRate(rate) {
    loadmgr.setRate(rate);
}
function createShader(gl, code, type) {
    const shader = gl.createShader(type);
    if (!shader) {
        throw Error('createShader failed');
    }
    gl.shaderSource(shader, code);
    gl.compileShader(shader);
    if (!gl.getShaderParameter(shader, 35713 /* GL.COMPILE_STATUS */)) {
        const msg = gl.getShaderInfoLog(shader);
        throw Error(msg);
    }
    return shader;
}


/***/ },

/***/ "./src/assets/webgl2.b64.glsl"
(module) {

module.exports = "I3ZlcnNpb24gMzAwIGVzCgpwcmVjaXNpb24gaGlnaHAgaW50OwpwcmVjaXNpb24gaGlnaHAgZmxvYXQ7Cgp1bmlmb3JtIHVpbnQgaW5fdzU7CnVuaWZvcm0gdWludCBpbl9zdGVwOwoKb3V0IHV2ZWM0IG91dF92OwoKCi8vIFNIQTI1NiB1dGlscwojZGVmaW5lIENoKHgsIHksIHopICAgKCh4ICYgKHkgXiB6KSkgXiB6KQojZGVmaW5lIE1haih4LCB5LCB6KSAgKCh4ICYgKHkgfCB6KSkgfCAoeSAmIHopKQojZGVmaW5lIFNIUih4LCBuKSAgICAgKHggPj4gbikKI2RlZmluZSBST1RSKHgsIG4pICAgICgoeCA+PiBuKSB8ICh4IDw8ICgzMiAtIG4pKSkKCiNkZWZpbmUgUzAoeCkgICAgICAgICAoUk9UUih4LCAgMikgXiBST1RSKHgsIDEzKSBeIFJPVFIoeCwgMjIpKQojZGVmaW5lIFMxKHgpICAgICAgICAgKFJPVFIoeCwgIDYpIF4gUk9UUih4LCAxMSkgXiBST1RSKHgsIDI1KSkKI2RlZmluZSBzMCh4KSAgICAgICAgIChST1RSKHgsICA3KSBeIFJPVFIoeCwgMTgpIF4gU0hSKHgsIDMpKQojZGVmaW5lIHMxKHgpICAgICAgICAgKFJPVFIoeCwgMTcpIF4gUk9UUih4LCAxOSkgXiBTSFIoeCwgMTApKQoKLyogU0hBMjU2IHJvdW5kIGZ1bmN0aW9uICovCiNkZWZpbmUgUk5EKGEsIGIsIGMsIGQsIGUsIGYsIGcsIGgsIGspICBcCiAgdDAgPSBoICsgUzEoZSkgKyBDaChlLCBmLCBnKSArIGs7ICAgICBcCiAgdDEgPSBTMChhKSArIE1haihhLCBiLCBjKTsgICAgICAgICAgICBcCiAgZCArPSB0MDsgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBcCiAgaCAgPSB0MCArIHQxOwoKCmNvbnN0IHVpbnQgS1s2NF0gPSB1aW50WzY0XSAoCiAgMHg0MjhBMkY5OHUsIDB4NzEzNzQ0OTF1LCAweEI1QzBGQkNGdSwgMHhFOUI1REJBNXUsCiAgMHgzOTU2QzI1QnUsIDB4NTlGMTExRjF1LCAweDkyM0Y4MkE0dSwgMHhBQjFDNUVENXUsCiAgMHhEODA3QUE5OHUsIDB4MTI4MzVCMDF1LCAweDI0MzE4NUJFdSwgMHg1NTBDN0RDM3UsCiAgMHg3MkJFNUQ3NHUsIDB4ODBERUIxRkV1LCAweDlCREMwNkE3dSwgMHhDMTlCRjE3NHUsCiAgMHhFNDlCNjlDMXUsIDB4RUZCRTQ3ODZ1LCAweDBGQzE5REM2dSwgMHgyNDBDQTFDQ3UsCiAgMHgyREU5MkM2RnUsIDB4NEE3NDg0QUF1LCAweDVDQjBBOURDdSwgMHg3NkY5ODhEQXUsCiAgMHg5ODNFNTE1MnUsIDB4QTgzMUM2NkR1LCAweEIwMDMyN0M4dSwgMHhCRjU5N0ZDN3UsCiAgMHhDNkUwMEJGM3UsIDB4RDVBNzkxNDd1LCAweDA2Q0E2MzUxdSwgMHgxNDI5Mjk2N3UsCiAgMHgyN0I3MEE4NXUsIDB4MkUxQjIxMzh1LCAweDREMkM2REZDdSwgMHg1MzM4MEQxM3UsCiAgMHg2NTBBNzM1NHUsIDB4NzY2QTBBQkJ1LCAweDgxQzJDOTJFdSwgMHg5MjcyMkM4NXUsCiAgMHhBMkJGRThBMXUsIDB4QTgxQTY2NEJ1LCAweEMyNEI4QjcwdSwgMHhDNzZDNTFBM3UsCiAgMHhEMTkyRTgxOXUsIDB4RDY5OTA2MjR1LCAweEY0MEUzNTg1dSwgMHgxMDZBQTA3MHUsCiAgMHgxOUE0QzExNnUsIDB4MUUzNzZDMDh1LCAweDI3NDg3NzRDdSwgMHgzNEIwQkNCNXUsCiAgMHgzOTFDMENCM3UsIDB4NEVEOEFBNEF1LCAweDVCOUNDQTRGdSwgMHg2ODJFNkZGM3UsCiAgMHg3NDhGODJFRXUsIDB4NzhBNTYzNkZ1LCAweDg0Qzg3ODE0dSwgMHg4Q0M3MDIwOHUsCiAgMHg5MEJFRkZGQXUsIDB4QTQ1MDZDRUJ1LCAweEJFRjlBM0Y3dSwgMHhDNjcxNzhGMnUKKTsKCnZvaWQgbWFpbigpIHsKICB1aW50IHggPSB1aW50KGdsX0ZyYWdDb29yZC54KTsKICB1aW50IHkgPSB1aW50KGdsX0ZyYWdDb29yZC55KTsKICB1aW50IHRocmVhZF9pZCA9IHkgKiBfX1RFWF9XX191ICsgeDsKCiAgdWludCBXWzE2XSwgU1s4XTsKICB1aW50IHQwLCB0MTsKCiAgZm9yICh1aW50IGkgPSBpbl9zdGVwOyBpID4gMHU7IGktLSkgewogICAgU1swXSA9IDB4NkEwOUU2Njd1OwogICAgU1sxXSA9IDB4QkI2N0FFODV1OwogICAgU1syXSA9IDB4M0M2RUYzNzJ1OwogICAgU1szXSA9IDB4QTU0RkY1M0F1OwogICAgU1s0XSA9IDB4NTEwRTUyN0Z1OwogICAgU1s1XSA9IDB4OUIwNTY4OEN1OwogICAgU1s2XSA9IDB4MUY4M0Q5QUJ1OwogICAgU1s3XSA9IDB4NUJFMENEMTl1OwoKICAgIC8vIGNoYWxsZW5nZQogICAgV1swXSA9IF9fVzBfX3U7CiAgICBXWzFdID0gX19XMV9fdTsKICAgIFdbMl0gPSBfX1cyX191OwogICAgV1szXSA9IF9fVzNfX3U7CgogICAgLy8gbm9uY2UKICAgIFdbNF0gPSBfX1c0X191OwogICAgV1s1XSA9IGluX3c1OwogICAgV1s2XSA9IHRocmVhZF9pZDsKICAgIFdbN10gPSBpOwoKICAgIC8vIHBhZGRpbmcKICAgIFdbOF0gPSAweDgwMDAwMDAwdTsgLy8gMSA8PCAzMQogICAgV1s5XSA9IDB1OwogICAgV1sxMF0gPSAwdTsKICAgIFdbMTFdID0gMHU7CiAgICBXWzEyXSA9IDB1OwogICAgV1sxM10gPSAwdTsKICAgIFdbMTRdID0gMHU7CiAgICBXWzE1XSA9IDI1NnU7ICAgICAgIC8vIGlucHV0IGJpdCBsZW4KCiAgICBSTkQoU1swXSwgU1sxXSwgU1syXSwgU1szXSwgU1s0XSwgU1s1XSwgU1s2XSwgU1s3XSwgV1sgMF0gKyBLWzBdKQogICAgUk5EKFNbN10sIFNbMF0sIFNbMV0sIFNbMl0sIFNbM10sIFNbNF0sIFNbNV0sIFNbNl0sIFdbIDFdICsgS1sxXSkKICAgIFJORChTWzZdLCBTWzddLCBTWzBdLCBTWzFdLCBTWzJdLCBTWzNdLCBTWzRdLCBTWzVdLCBXWyAyXSArIEtbMl0pCiAgICBSTkQoU1s1XSwgU1s2XSwgU1s3XSwgU1swXSwgU1sxXSwgU1syXSwgU1szXSwgU1s0XSwgV1sgM10gKyBLWzNdKQogICAgUk5EKFNbNF0sIFNbNV0sIFNbNl0sIFNbN10sIFNbMF0sIFNbMV0sIFNbMl0sIFNbM10sIFdbIDRdICsgS1s0XSkKICAgIFJORChTWzNdLCBTWzRdLCBTWzVdLCBTWzZdLCBTWzddLCBTWzBdLCBTWzFdLCBTWzJdLCBXWyA1XSArIEtbNV0pCiAgICBSTkQoU1syXSwgU1szXSwgU1s0XSwgU1s1XSwgU1s2XSwgU1s3XSwgU1swXSwgU1sxXSwgV1sgNl0gKyBLWzZdKQogICAgUk5EKFNbMV0sIFNbMl0sIFNbM10sIFNbNF0sIFNbNV0sIFNbNl0sIFNbN10sIFNbMF0sIFdbIDddICsgS1s3XSkKICAgIFJORChTWzBdLCBTWzFdLCBTWzJdLCBTWzNdLCBTWzRdLCBTWzVdLCBTWzZdLCBTWzddLCBXWyA4XSArIEtbOF0pCiAgICBSTkQoU1s3XSwgU1swXSwgU1sxXSwgU1syXSwgU1szXSwgU1s0XSwgU1s1XSwgU1s2XSwgV1sgOV0gKyBLWzldKQogICAgUk5EKFNbNl0sIFNbN10sIFNbMF0sIFNbMV0sIFNbMl0sIFNbM10sIFNbNF0sIFNbNV0sIFdbMTBdICsgS1sxMF0pCiAgICBSTkQoU1s1XSwgU1s2XSwgU1s3XSwgU1swXSwgU1sxXSwgU1syXSwgU1szXSwgU1s0XSwgV1sxMV0gKyBLWzExXSkKICAgIFJORChTWzRdLCBTWzVdLCBTWzZdLCBTWzddLCBTWzBdLCBTWzFdLCBTWzJdLCBTWzNdLCBXWzEyXSArIEtbMTJdKQogICAgUk5EKFNbM10sIFNbNF0sIFNbNV0sIFNbNl0sIFNbN10sIFNbMF0sIFNbMV0sIFNbMl0sIFdbMTNdICsgS1sxM10pCiAgICBSTkQoU1syXSwgU1szXSwgU1s0XSwgU1s1XSwgU1s2XSwgU1s3XSwgU1swXSwgU1sxXSwgV1sxNF0gKyBLWzE0XSkKICAgIFJORChTWzFdLCBTWzJdLCBTWzNdLCBTWzRdLCBTWzVdLCBTWzZdLCBTWzddLCBTWzBdLCBXWzE1XSArIEtbMTVdKQoKICAgIFdbIDBdICs9IHMxKFdbMTRdKSArIFdbIDldICsgczAoV1sgMV0pOwogICAgV1sgMV0gKz0gczEoV1sxNV0pICsgV1sxMF0gKyBzMChXWyAyXSk7CiAgICBXWyAyXSArPSBzMShXWyAwXSkgKyBXWzExXSArIHMwKFdbIDNdKTsKICAgIFdbIDNdICs9IHMxKFdbIDFdKSArIFdbMTJdICsgczAoV1sgNF0pOwogICAgV1sgNF0gKz0gczEoV1sgMl0pICsgV1sxM10gKyBzMChXWyA1XSk7CiAgICBXWyA1XSArPSBzMShXWyAzXSkgKyBXWzE0XSArIHMwKFdbIDZdKTsKICAgIFdbIDZdICs9IHMxKFdbIDRdKSArIFdbMTVdICsgczAoV1sgN10pOwogICAgV1sgN10gKz0gczEoV1sgNV0pICsgV1sgMF0gKyBzMChXWyA4XSk7CiAgICBXWyA4XSArPSBzMShXWyA2XSkgKyBXWyAxXSArIHMwKFdbIDldKTsKICAgIFdbIDldICs9IHMxKFdbIDddKSArIFdbIDJdICsgczAoV1sxMF0pOwogICAgV1sxMF0gKz0gczEoV1sgOF0pICsgV1sgM10gKyBzMChXWzExXSk7CiAgICBXWzExXSArPSBzMShXWyA5XSkgKyBXWyA0XSArIHMwKFdbMTJdKTsKICAgIFdbMTJdICs9IHMxKFdbMTBdKSArIFdbIDVdICsgczAoV1sxM10pOwogICAgV1sxM10gKz0gczEoV1sxMV0pICsgV1sgNl0gKyBzMChXWzE0XSk7CiAgICBXWzE0XSArPSBzMShXWzEyXSkgKyBXWyA3XSArIHMwKFdbMTVdKTsKICAgIFdbMTVdICs9IHMxKFdbMTNdKSArIFdbIDhdICsgczAoV1sgMF0pOwoKICAgIFJORChTWzBdLCBTWzFdLCBTWzJdLCBTWzNdLCBTWzRdLCBTWzVdLCBTWzZdLCBTWzddLCBXWyAwXSArIEtbMTZdKQogICAgUk5EKFNbN10sIFNbMF0sIFNbMV0sIFNbMl0sIFNbM10sIFNbNF0sIFNbNV0sIFNbNl0sIFdbIDFdICsgS1sxN10pCiAgICBSTkQoU1s2XSwgU1s3XSwgU1swXSwgU1sxXSwgU1syXSwgU1szXSwgU1s0XSwgU1s1XSwgV1sgMl0gKyBLWzE4XSkKICAgIFJORChTWzVdLCBTWzZdLCBTWzddLCBTWzBdLCBTWzFdLCBTWzJdLCBTWzNdLCBTWzRdLCBXWyAzXSArIEtbMTldKQogICAgUk5EKFNbNF0sIFNbNV0sIFNbNl0sIFNbN10sIFNbMF0sIFNbMV0sIFNbMl0sIFNbM10sIFdbIDRdICsgS1syMF0pCiAgICBSTkQoU1szXSwgU1s0XSwgU1s1XSwgU1s2XSwgU1s3XSwgU1swXSwgU1sxXSwgU1syXSwgV1sgNV0gKyBLWzIxXSkKICAgIFJORChTWzJdLCBTWzNdLCBTWzRdLCBTWzVdLCBTWzZdLCBTWzddLCBTWzBdLCBTWzFdLCBXWyA2XSArIEtbMjJdKQogICAgUk5EKFNbMV0sIFNbMl0sIFNbM10sIFNbNF0sIFNbNV0sIFNbNl0sIFNbN10sIFNbMF0sIFdbIDddICsgS1syM10pCiAgICBSTkQoU1swXSwgU1sxXSwgU1syXSwgU1szXSwgU1s0XSwgU1s1XSwgU1s2XSwgU1s3XSwgV1sgOF0gKyBLWzI0XSkKICAgIFJORChTWzddLCBTWzBdLCBTWzFdLCBTWzJdLCBTWzNdLCBTWzRdLCBTWzVdLCBTWzZdLCBXWyA5XSArIEtbMjVdKQogICAgUk5EKFNbNl0sIFNbN10sIFNbMF0sIFNbMV0sIFNbMl0sIFNbM10sIFNbNF0sIFNbNV0sIFdbMTBdICsgS1syNl0pCiAgICBSTkQoU1s1XSwgU1s2XSwgU1s3XSwgU1swXSwgU1sxXSwgU1syXSwgU1szXSwgU1s0XSwgV1sxMV0gKyBLWzI3XSkKICAgIFJORChTWzRdLCBTWzVdLCBTWzZdLCBTWzddLCBTWzBdLCBTWzFdLCBTWzJdLCBTWzNdLCBXWzEyXSArIEtbMjhdKQogICAgUk5EKFNbM10sIFNbNF0sIFNbNV0sIFNbNl0sIFNbN10sIFNbMF0sIFNbMV0sIFNbMl0sIFdbMTNdICsgS1syOV0pCiAgICBSTkQoU1syXSwgU1szXSwgU1s0XSwgU1s1XSwgU1s2XSwgU1s3XSwgU1swXSwgU1sxXSwgV1sxNF0gKyBLWzMwXSkKICAgIFJORChTWzFdLCBTWzJdLCBTWzNdLCBTWzRdLCBTWzVdLCBTWzZdLCBTWzddLCBTWzBdLCBXWzE1XSArIEtbMzFdKQoKICAgIFdbIDBdICs9IHMxKFdbMTRdKSArIFdbIDldICsgczAoV1sgMV0pOwogICAgV1sgMV0gKz0gczEoV1sxNV0pICsgV1sxMF0gKyBzMChXWyAyXSk7CiAgICBXWyAyXSArPSBzMShXWyAwXSkgKyBXWzExXSArIHMwKFdbIDNdKTsKICAgIFdbIDNdICs9IHMxKFdbIDFdKSArIFdbMTJdICsgczAoV1sgNF0pOwogICAgV1sgNF0gKz0gczEoV1sgMl0pICsgV1sxM10gKyBzMChXWyA1XSk7CiAgICBXWyA1XSArPSBzMShXWyAzXSkgKyBXWzE0XSArIHMwKFdbIDZdKTsKICAgIFdbIDZdICs9IHMxKFdbIDRdKSArIFdbMTVdICsgczAoV1sgN10pOwogICAgV1sgN10gKz0gczEoV1sgNV0pICsgV1sgMF0gKyBzMChXWyA4XSk7CiAgICBXWyA4XSArPSBzMShXWyA2XSkgKyBXWyAxXSArIHMwKFdbIDldKTsKICAgIFdbIDldICs9IHMxKFdbIDddKSArIFdbIDJdICsgczAoV1sxMF0pOwogICAgV1sxMF0gKz0gczEoV1sgOF0pICsgV1sgM10gKyBzMChXWzExXSk7CiAgICBXWzExXSArPSBzMShXWyA5XSkgKyBXWyA0XSArIHMwKFdbMTJdKTsKICAgIFdbMTJdICs9IHMxKFdbMTBdKSArIFdbIDVdICsgczAoV1sxM10pOwogICAgV1sxM10gKz0gczEoV1sxMV0pICsgV1sgNl0gKyBzMChXWzE0XSk7CiAgICBXWzE0XSArPSBzMShXWzEyXSkgKyBXWyA3XSArIHMwKFdbMTVdKTsKICAgIFdbMTVdICs9IHMxKFdbMTNdKSArIFdbIDhdICsgczAoV1sgMF0pOwoKICAgIFJORChTWzBdLCBTWzFdLCBTWzJdLCBTWzNdLCBTWzRdLCBTWzVdLCBTWzZdLCBTWzddLCBXWyAwXSArIEtbMzJdKQogICAgUk5EKFNbN10sIFNbMF0sIFNbMV0sIFNbMl0sIFNbM10sIFNbNF0sIFNbNV0sIFNbNl0sIFdbIDFdICsgS1szM10pCiAgICBSTkQoU1s2XSwgU1s3XSwgU1swXSwgU1sxXSwgU1syXSwgU1szXSwgU1s0XSwgU1s1XSwgV1sgMl0gKyBLWzM0XSkKICAgIFJORChTWzVdLCBTWzZdLCBTWzddLCBTWzBdLCBTWzFdLCBTWzJdLCBTWzNdLCBTWzRdLCBXWyAzXSArIEtbMzVdKQogICAgUk5EKFNbNF0sIFNbNV0sIFNbNl0sIFNbN10sIFNbMF0sIFNbMV0sIFNbMl0sIFNbM10sIFdbIDRdICsgS1szNl0pCiAgICBSTkQoU1szXSwgU1s0XSwgU1s1XSwgU1s2XSwgU1s3XSwgU1swXSwgU1sxXSwgU1syXSwgV1sgNV0gKyBLWzM3XSkKICAgIFJORChTWzJdLCBTWzNdLCBTWzRdLCBTWzVdLCBTWzZdLCBTWzddLCBTWzBdLCBTWzFdLCBXWyA2XSArIEtbMzhdKQogICAgUk5EKFNbMV0sIFNbMl0sIFNbM10sIFNbNF0sIFNbNV0sIFNbNl0sIFNbN10sIFNbMF0sIFdbIDddICsgS1szOV0pCiAgICBSTkQoU1swXSwgU1sxXSwgU1syXSwgU1szXSwgU1s0XSwgU1s1XSwgU1s2XSwgU1s3XSwgV1sgOF0gKyBLWzQwXSkKICAgIFJORChTWzddLCBTWzBdLCBTWzFdLCBTWzJdLCBTWzNdLCBTWzRdLCBTWzVdLCBTWzZdLCBXWyA5XSArIEtbNDFdKQogICAgUk5EKFNbNl0sIFNbN10sIFNbMF0sIFNbMV0sIFNbMl0sIFNbM10sIFNbNF0sIFNbNV0sIFdbMTBdICsgS1s0Ml0pCiAgICBSTkQoU1s1XSwgU1s2XSwgU1s3XSwgU1swXSwgU1sxXSwgU1syXSwgU1szXSwgU1s0XSwgV1sxMV0gKyBLWzQzXSkKICAgIFJORChTWzRdLCBTWzVdLCBTWzZdLCBTWzddLCBTWzBdLCBTWzFdLCBTWzJdLCBTWzNdLCBXWzEyXSArIEtbNDRdKQogICAgUk5EKFNbM10sIFNbNF0sIFNbNV0sIFNbNl0sIFNbN10sIFNbMF0sIFNbMV0sIFNbMl0sIFdbMTNdICsgS1s0NV0pCiAgICBSTkQoU1syXSwgU1szXSwgU1s0XSwgU1s1XSwgU1s2XSwgU1s3XSwgU1swXSwgU1sxXSwgV1sxNF0gKyBLWzQ2XSkKICAgIFJORChTWzFdLCBTWzJdLCBTWzNdLCBTWzRdLCBTWzVdLCBTWzZdLCBTWzddLCBTWzBdLCBXWzE1XSArIEtbNDddKQoKICAgIFdbIDBdICs9IHMxKFdbMTRdKSArIFdbIDldICsgczAoV1sgMV0pOwogICAgV1sgMV0gKz0gczEoV1sxNV0pICsgV1sxMF0gKyBzMChXWyAyXSk7CiAgICBXWyAyXSArPSBzMShXWyAwXSkgKyBXWzExXSArIHMwKFdbIDNdKTsKICAgIFdbIDNdICs9IHMxKFdbIDFdKSArIFdbMTJdICsgczAoV1sgNF0pOwogICAgV1sgNF0gKz0gczEoV1sgMl0pICsgV1sxM10gKyBzMChXWyA1XSk7CiAgICBXWyA1XSArPSBzMShXWyAzXSkgKyBXWzE0XSArIHMwKFdbIDZdKTsKICAgIFdbIDZdICs9IHMxKFdbIDRdKSArIFdbMTVdICsgczAoV1sgN10pOwogICAgV1sgN10gKz0gczEoV1sgNV0pICsgV1sgMF0gKyBzMChXWyA4XSk7CiAgICBXWyA4XSArPSBzMShXWyA2XSkgKyBXWyAxXSArIHMwKFdbIDldKTsKICAgIFdbIDldICs9IHMxKFdbIDddKSArIFdbIDJdICsgczAoV1sxMF0pOwogICAgV1sxMF0gKz0gczEoV1sgOF0pICsgV1sgM10gKyBzMChXWzExXSk7CiAgICBXWzExXSArPSBzMShXWyA5XSkgKyBXWyA0XSArIHMwKFdbMTJdKTsKICAgIFdbMTJdICs9IHMxKFdbMTBdKSArIFdbIDVdICsgczAoV1sxM10pOwogICAgV1sxM10gKz0gczEoV1sxMV0pICsgV1sgNl0gKyBzMChXWzE0XSk7CiAgICBXWzE0XSArPSBzMShXWzEyXSkgKyBXWyA3XSArIHMwKFdbMTVdKTsKICAgIFdbMTVdICs9IHMxKFdbMTNdKSArIFdbIDhdICsgczAoV1sgMF0pOwoKICAgIFJORChTWzBdLCBTWzFdLCBTWzJdLCBTWzNdLCBTWzRdLCBTWzVdLCBTWzZdLCBTWzddLCBXWyAwXSArIEtbNDhdKQogICAgUk5EKFNbN10sIFNbMF0sIFNbMV0sIFNbMl0sIFNbM10sIFNbNF0sIFNbNV0sIFNbNl0sIFdbIDFdICsgS1s0OV0pCiAgICBSTkQoU1s2XSwgU1s3XSwgU1swXSwgU1sxXSwgU1syXSwgU1szXSwgU1s0XSwgU1s1XSwgV1sgMl0gKyBLWzUwXSkKICAgIFJORChTWzVdLCBTWzZdLCBTWzddLCBTWzBdLCBTWzFdLCBTWzJdLCBTWzNdLCBTWzRdLCBXWyAzXSArIEtbNTFdKQogICAgUk5EKFNbNF0sIFNbNV0sIFNbNl0sIFNbN10sIFNbMF0sIFNbMV0sIFNbMl0sIFNbM10sIFdbIDRdICsgS1s1Ml0pCiAgICBSTkQoU1szXSwgU1s0XSwgU1s1XSwgU1s2XSwgU1s3XSwgU1swXSwgU1sxXSwgU1syXSwgV1sgNV0gKyBLWzUzXSkKICAgIFJORChTWzJdLCBTWzNdLCBTWzRdLCBTWzVdLCBTWzZdLCBTWzddLCBTWzBdLCBTWzFdLCBXWyA2XSArIEtbNTRdKQogICAgUk5EKFNbMV0sIFNbMl0sIFNbM10sIFNbNF0sIFNbNV0sIFNbNl0sIFNbN10sIFNbMF0sIFdbIDddICsgS1s1NV0pCiAgICBSTkQoU1swXSwgU1sxXSwgU1syXSwgU1szXSwgU1s0XSwgU1s1XSwgU1s2XSwgU1s3XSwgV1sgOF0gKyBLWzU2XSkKICAgIFJORChTWzddLCBTWzBdLCBTWzFdLCBTWzJdLCBTWzNdLCBTWzRdLCBTWzVdLCBTWzZdLCBXWyA5XSArIEtbNTddKQogICAgUk5EKFNbNl0sIFNbN10sIFNbMF0sIFNbMV0sIFNbMl0sIFNbM10sIFNbNF0sIFNbNV0sIFdbMTBdICsgS1s1OF0pCiAgICBSTkQoU1s1XSwgU1s2XSwgU1s3XSwgU1swXSwgU1sxXSwgU1syXSwgU1szXSwgU1s0XSwgV1sxMV0gKyBLWzU5XSkKICAgIFJORChTWzRdLCBTWzVdLCBTWzZdLCBTWzddLCBTWzBdLCBTWzFdLCBTWzJdLCBTWzNdLCBXWzEyXSArIEtbNjBdKQogICAgUk5EKFNbM10sIFNbNF0sIFNbNV0sIFNbNl0sIFNbN10sIFNbMF0sIFNbMV0sIFNbMl0sIFdbMTNdICsgS1s2MV0pCiAgICBSTkQoU1syXSwgU1szXSwgU1s0XSwgU1s1XSwgU1s2XSwgU1s3XSwgU1swXSwgU1sxXSwgV1sxNF0gKyBLWzYyXSkKICAgIFJORChTWzFdLCBTWzJdLCBTWzNdLCBTWzRdLCBTWzVdLCBTWzZdLCBTWzddLCBTWzBdLCBXWzE1XSArIEtbNjNdKQoKICAgIGlmICgwdSA9PSAoKFNbMF0gKyAweDZBMDlFNjY3dSkgJiBfX01BU0swX191KSAmJgogICAgICAgIDB1ID09ICgoU1sxXSArIDB4QkI2N0FFODV1KSAmIF9fTUFTSzFfX3UpCiAgICApIHsKICAgICAgb3V0X3YgPSB1dmVjNCgwdSwgX19NQUdJQ19DT0RFX191LCB0aHJlYWRfaWQsIGkpOwogICAgICByZXR1cm47CiAgICB9CiAgfQogIGRpc2NhcmQ7Cn0K";

/***/ }

/******/ });
/************************************************************************/
/******/ // The module cache
/******/ var __webpack_module_cache__ = {};
/******/ 
/******/ // The require function
/******/ function __webpack_require__(moduleId) {
/******/ 	// Check if module is in cache
/******/ 	var cachedModule = __webpack_module_cache__[moduleId];
/******/ 	if (cachedModule !== undefined) {
/******/ 		return cachedModule.exports;
/******/ 	}
/******/ 	// Create a new module (and put it into the cache)
/******/ 	var module = __webpack_module_cache__[moduleId] = {
/******/ 		// no module.id needed
/******/ 		// no module.loaded needed
/******/ 		exports: {}
/******/ 	};
/******/ 
/******/ 	// Execute the module function
/******/ 	__webpack_modules__[moduleId](module, module.exports, __webpack_require__);
/******/ 
/******/ 	// Return the exports of the module
/******/ 	return module.exports;
/******/ }
/******/ 
/************************************************************************/
/******/ /* webpack/runtime/define property getters */
/******/ (() => {
/******/ 	// define getter functions for harmony exports
/******/ 	__webpack_require__.d = (exports, definition) => {
/******/ 		for(var key in definition) {
/******/ 			if(__webpack_require__.o(definition, key) && !__webpack_require__.o(exports, key)) {
/******/ 				Object.defineProperty(exports, key, { enumerable: true, get: definition[key] });
/******/ 			}
/******/ 		}
/******/ 	};
/******/ })();
/******/ 
/******/ /* webpack/runtime/hasOwnProperty shorthand */
/******/ (() => {
/******/ 	__webpack_require__.o = (obj, prop) => (Object.prototype.hasOwnProperty.call(obj, prop))
/******/ })();
/******/ 
/******/ /* webpack/runtime/make namespace object */
/******/ (() => {
/******/ 	// define __esModule on exports
/******/ 	__webpack_require__.r = (exports) => {
/******/ 		if(typeof Symbol !== 'undefined' && Symbol.toStringTag) {
/******/ 			Object.defineProperty(exports, Symbol.toStringTag, { value: 'Module' });
/******/ 		}
/******/ 		Object.defineProperty(exports, '__esModule', { value: true });
/******/ 	};
/******/ })();
/******/ 
/************************************************************************/
var __webpack_exports__ = {};
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   fromB64: () => (/* binding */ fromB64),
/* harmony export */   pow: () => (/* binding */ pow),
/* harmony export */   stop: () => (/* binding */ stop),
/* harmony export */   toB64: () => (/* binding */ toB64)
/* harmony export */ });
/* harmony import */ var _webgl2__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__("./src/webgl2.ts");
/* harmony import */ var _util__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__("./src/util.ts");


let isRunning;
let gpuMod = _webgl2__WEBPACK_IMPORTED_MODULE_0__;
function eventHandler(resolve, reject) {
    return {
        onProgress(step, workerId) {
            console.log(step);
        },
        onComplete(nonce) {
            if (!isRunning) {
                return;
            }
            stop();
            for (let i = 0; i < 4; i++) {
                nonce[i] = (0,_util__WEBPACK_IMPORTED_MODULE_1__.bswap)(nonce[i]);
            }
            const bytes = new Uint8Array(nonce.buffer);
            resolve(toB64(bytes));
        },
        onError(err) {
            reject(err);
        },
    };
}
function fromB64(base64) {
    const binaryString = atob(base64);
    const bytes = new Uint8Array(binaryString.length);
    for (let i = 0; i < binaryString.length; i++) {
        bytes[i] = binaryString.charCodeAt(i);
    }
    return bytes;
}
function toB64(bytes) {
    let binaryString = '';
    for (let i = 0; i < bytes.length; i++) {
        binaryString += String.fromCharCode(bytes[i]);
    }
    return btoa(binaryString);
}
async function pow(challenge, difficulty) {
    return new Promise((resolve, reject) => {
        _webgl2__WEBPACK_IMPORTED_MODULE_0__.init(eventHandler(resolve, reject));
        console.log('challenge', challenge);
        const words = new Uint32Array(fromB64(challenge).buffer);
        const masks = new Uint32Array(2);
        for (let i = 0; i < 4; i++) {
            words[i] = (0,_util__WEBPACK_IMPORTED_MODULE_1__.bswap)(words[i]);
        }
        if (difficulty > 32) {
            masks[0] = -1;
            masks[1] = -1 << (64 - difficulty);
        }
        else {
            masks[0] = -1 << (32 - difficulty);
        }
        isRunning = true;
        gpuMod.start(words, masks);
    });
}
function stop() {
    gpuMod.stop();
    isRunning = false;
}

var __webpack_export_target__ = self;
for(var __webpack_i__ in __webpack_exports__) __webpack_export_target__[__webpack_i__] = __webpack_exports__[__webpack_i__];
if(__webpack_exports__.__esModule) Object.defineProperty(__webpack_export_target__, "__esModule", { value: true });

//# sourceMappingURL=index.js.map</script></head><body><div class="loading-container"><div class="spinner"></div><p class="loading-text">Please wait. This page is protected by</p><img width="100%" alt="" src="data:image/png;base64,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"/><div style="text-align: left;" class="loading-text"><a href="https://humansgate.com">Learn More</a></div></div><script type="module">const challenge = '{{{challenge}}}';
    const difficulty   = {{{difficulty}}};
    const url   = '{{{url}}}';

    function commitResult(nonce) {
        const params = new URLSearchParams(window.location.search);
        params.set("nonce", nonce);
        params.set("url", url);
        window.location.search = params.toString();
    }


    pow(challenge, difficulty)
        .then((nonce) => commitResult(nonce))
        .catch((err) => console.error(err));</script></body></html>

''';
