'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "a6e1d660a4771acd8c7235f92a5cd247",
"version.json": "5ffd0226321d0f54da52756ddc9ce228",
"splash/img/light-2x.png": "ece7bc804e52c3bbd0d62392ac4934a7",
"splash/img/dark-4x.png": "f1ffaabaed4c0a72332488714c92d456",
"splash/img/light-3x.png": "9e4aaf12d14b7062581418c270a5c975",
"splash/img/dark-3x.png": "9e4aaf12d14b7062581418c270a5c975",
"splash/img/light-4x.png": "f1ffaabaed4c0a72332488714c92d456",
"splash/img/dark-2x.png": "ece7bc804e52c3bbd0d62392ac4934a7",
"splash/img/dark-1x.png": "5d6a68c218b54caae8ad9dce6aeabd2f",
"splash/img/light-1x.png": "5d6a68c218b54caae8ad9dce6aeabd2f",
"index.html": "382fd5bf0156a62b419bf88928efc3c3",
"/": "382fd5bf0156a62b419bf88928efc3c3",
"main.dart.js": "002f78dc655492648edd7bea788c7fd4",
"flutter.js": "76f08d47ff9f5715220992f993002504",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"manifest.json": "6ee3de90ad4d1889843d79fdd3726df7",
"assets/AssetManifest.json": "7cd826b6c6bd28f4f840c6f1308d91ef",
"assets/NOTICES": "4d59f8e98befd5ea8497566c48ebb672",
"assets/FontManifest.json": "e319f8e63262f6118daad7646e484ee7",
"assets/AssetManifest.bin.json": "ffbaba4dc88d43fe467101fef0615b16",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "a86b61298457534aabb3750c8683e496",
"assets/packages/iconsax/lib/assets/fonts/iconsax.ttf": "071d77779414a409552e0584dcbfd03d",
"assets/packages/phosphor_flutter/lib/fonts/Phosphor-Duotone.ttf": "c48df336708c750389fa8d06ec830dab",
"assets/packages/phosphor_flutter/lib/fonts/Phosphor-Fill.ttf": "5d304fa130484129be6bf4b79a675638",
"assets/packages/phosphor_flutter/lib/fonts/Phosphor.ttf": "003d691b53ee8fab57d5db497ddc54db",
"assets/packages/phosphor_flutter/lib/fonts/Phosphor-Light.ttf": "f2dc1cd993671b155e3235044280ba47",
"assets/packages/phosphor_flutter/lib/fonts/Phosphor-Bold.ttf": "8fedcf7067a22a2a320214168689b05c",
"assets/packages/phosphor_flutter/lib/fonts/Phosphor-Thin.ttf": "f128e0009c7b98aba23cafe9c2a5eb06",
"assets/packages/fluttertoast/assets/toastify.js": "56e2c9cedd97f10e7e5f1cebd85d53e3",
"assets/packages/fluttertoast/assets/toastify.css": "a85675050054f179444bc5ad70ffc635",
"assets/packages/record_web/assets/js/record.fixwebmduration.js": "1f0108ea80c8951ba702ced40cf8cdce",
"assets/packages/record_web/assets/js/record.worklet.js": "8a5f575ecdf23f21bcae8204882d54bb",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "498d86c4f3ca6cda1280a3bf224865a9",
"assets/fonts/MaterialIcons-Regular.otf": "8ead1aeaf70ab7822a165c84073d6ece",
"assets/assets/images/port.png": "5d54b52e6a193e1ea43c9f6b00516401",
"assets/assets/images/new_loader.json": "4d59a48f59cbd5c1fa0d71bb151a21dc",
"assets/assets/images/%25E0%25A4%25B5%25E0%25A4%25BF%25E0%25A4%25A4%25E0%25A5%258D%25E0%25A4%25A4%25E0%25A5%2580%25E0%25A4%25AF2.png": "ed4c06e9101eeaec32c4889592d520ba",
"assets/assets/images/notes.svg": "3763711dcc11da3cc118a38bd512ffed",
"assets/assets/images/attach_vector.png": "e9a3795bdeefba31cbe1617e9ec65c6e",
"assets/assets/images/new_notification.svg": "ca617884e0f19acbb60444ffc84df7fb",
"assets/assets/images/img_1.png": "94a692cb76b69b52f89f7cfd29e0c7eb",
"assets/assets/images/convo.svg": "e7872ca7a8ffda6a896613c5c008289b",
"assets/assets/images/Mask%2520group.png": "7a3507050a2466fe145b5c135d17a3c6",
"assets/assets/images/cleaned_vitty_loader.json": "0f1a243b655054331f33007efca26822",
"assets/assets/images/retry2.json": "9f9d73fa6e78035149434f35ff207f1f",
"assets/assets/images/newChat.svg": "82352ef4f856e983e728457cd20664a5",
"assets/assets/images/clean.gif": "ddc61c8b3f5e5871ca397ee6fc572749",
"assets/assets/images/face_id.svg": "efd0a29da04aac2236bad79733390a7d",
"assets/assets/images/drawer_new.svg": "4afcbf3f6dd74a23bc9a81392411452f",
"assets/assets/images/orb2.json": "bff473d58e71c45651c2ece9368573db",
"assets/assets/images/auth.png": "50eba3f3c5bfea27dd982c51d381a70f",
"assets/assets/images/Website%2520Animation.json": "c9bcf4b4e45ba441114a99288d822cc7",
"assets/assets/images/retry3.json": "85f943b6465585e354134abe40ff52c2",
"assets/assets/images/research.svg": "2508ed318479ad58ce49ac0178b923c3",
"assets/assets/images/Vector.svg": "a456ec7a10a5e41ff4fd81e05bf6901a",
"assets/assets/images/%25E0%25A4%25B5%25E0%25A4%25BF%25E0%25A4%25A4%25E0%25A5%258D%25E0%25A4%25A4%25E0%25A5%2580%25E0%25A4%25AF.png": "16fbbfbaeed4fc493d845289f9c130ea",
"assets/assets/images/threads.png": "e4d4f77074e6caf21f67fa1be2d53323",
"assets/assets/images/svgattach.svg": "13a82316a9c8785e2aae1614c93690ef",
"assets/assets/images/downward.png": "0693d569ac111a12fb8edafbe70588d9",
"assets/assets/images/new_chat_ios.svg": "7acd057da4c65630757c2229eae5a8a8",
"assets/assets/images/green_bag.png": "3cb443f97889e7a4bb79b305dc35fa76",
"assets/assets/images/drawer.svg": "450573f0bcab084c9785072727e37c74",
"assets/assets/images/ioswhite.png": "d18c7d09c3e04b461d25a4fff2157bcb",
"assets/assets/images/icon_app_ios.png": "29cd22dad1705630ad6a3d3e0f290ae3",
"assets/assets/images/drawer.png": "b53e90933be5a3bd4842c982f7ffedbc",
"assets/assets/images/newest.png": "225aa45202217c779406ccbce942b8e4",
"assets/assets/images/Vector.png": "5143354eb14f5df0cbf1ef0580f0e7e8",
"assets/assets/images/cancel.png": "10049f39bc99d9091224c3d4f7d4798c",
"assets/assets/images/svgmic.svg": "7050ea876f6fec9a0ce159790d5adcaf",
"assets/assets/images/vitty_loader_o.json": "69e2b1350a56824ea33d914809fa61fd",
"assets/assets/images/pink.png": "d2b04802e79468162b3af686c3ffe26e",
"assets/assets/images/conversations_new.svg": "b8cc35cad2f7661203b973923b1405e3",
"assets/assets/images/Group%252010.png": "04a865a1eaa4b8e9e50763521efeb202",
"assets/assets/images/bold_mic.png": "094deed6da734ae7e8ef024b9b39b4a9",
"assets/assets/images/mics.png": "4ffb46d5e9f7306264525f64b39bc91d",
"assets/assets/images/newChat.png": "07ccdaf31545302b5ee10f20e0ffc10e",
"assets/assets/images/vitty_loader.json": "d5359dad9c2b07ef4e0888d244ee1a73",
"assets/assets/images/orb_back.webp": "5131a74493ee7dcd6405b7f1b17a6058",
"assets/assets/images/microsoft.png": "d9f10daa9fec1084fa207325b1e3f68d",
"assets/assets/images/orb.json": "8c1aea178175fa1d81b8d3c9d9105683",
"assets/assets/images/ios_chat_create.svg": "46039238ade4a19d07493d070a836824",
"assets/assets/images/wealth.svg": "cb705a3ffd0b83ae52785e8b6f39d48e",
"assets/assets/images/new_loader.gif": "ad6725d23da47377dd5bd79f17804189",
"assets/assets/images/Final_For_IOS.png": "ec888cc802fc1c6d883cd602e4a24760",
"assets/assets/images/notes.png": "960745ee18d22b860b0e9eb2908c9f33",
"assets/assets/images/upward.png": "f4dc410c800afefcf7b2380312575e9a",
"assets/assets/images/mic.svg": "12d7f4267847b744416caab0cb1d0a2e",
"assets/assets/images/mic_loading.json": "beec00c2fecbb00bc13c3bbb9d34eab9",
"assets/assets/images/logo_ios.png": "eb5a95e4a0102e01d88463240ae28345",
"assets/assets/images/mic_2.png": "e5aaf1ced48efed281df6cceaa9f2162",
"assets/assets/images/secret_chat.svg": "3cf6ddcecfb71eed5b7da2bc28a94326",
"assets/assets/images/gradient.gif": "b51cfaeaeae3d6dcb8f1891dd64cc75f",
"assets/assets/images/attach_2.png": "36f98f4cfbfed8d33ea700bc15f2b697",
"assets/assets/images/apple.png": "a6827f31cc96babfbf9b2127759e2887",
"assets/assets/images/graph.png": "78edecd256fde44bb7a680c7d20da367",
"assets/assets/images/ios_splash.png": "ba16898cc2e1311aec96e06b6b9d1b71",
"assets/assets/images/choose_broker.png": "b901cca09ec8dbf497922b2d06aa99c5",
"assets/assets/images/new_app_logo.png": "12d3fde5fb9f6a29779e99b84612fcfc",
"assets/assets/images/orb_json.json": "9f9d73fa6e78035149434f35ff207f1f",
"assets/assets/images/onboard_animate.png": "01d9f7b74550080f15f7765fceadda9e",
"assets/assets/images/attach.png": "bfecef5a00f4c295753e47082ec829af",
"assets/assets/images/loader_dark.json": "f5b9c5b180edd7e02a33ea5b5cd2f741",
"assets/assets/images/ying%2520yang%2520full.png": "5f36d1f8a7d1d08c1bf6fba0f30c6f0a",
"assets/assets/images/edit.svg": "992ff54e6cd0c42a82637abf5c57cf98",
"assets/assets/images/revised_orb.json": "b356d1b6e043d28eb1a48dc7abf91efb",
"assets/assets/images/ying%2520yang.png": "073ac2d261205fc36277c4f3f88587db",
"assets/assets/images/eye.png": "dc53e155e7d9a20d0789b64458638818",
"assets/assets/images/ying_yang_android.png": "f121318a21015a68f5f94be1a84ecaee",
"assets/assets/images/new_chat_ios1.svg": "b04bea76c00f6c88498447d0fba75b83",
"assets/assets/images/hero-orb.json": "c9bcf4b4e45ba441114a99288d822cc7",
"assets/assets/images/onboard.json": "47b8a3eebf0f9df5eb097cb9977bae7d",
"assets/assets/images/vitty.png": "bddb920d42b8e563aaca84d16b7b5b35",
"assets/assets/images/new_drawer.png": "afd22646c4f35bd4ea6b337ecf8b3543",
"assets/assets/images/orb.gif": "9a3423d5866b2fda4c923f4ca7d1ba56",
"assets/assets/images/new_loader_dark.gif": "eaafba4cd70bfa6f56030650ae526d72",
"assets/assets/images/delete.svg": "f9cc8c02b0ba4f99d03adccc6bdfda31",
"assets/assets/images/new_drawer.svg": "78dd6580ffe62c9e63808094601d1373",
"assets/assets/images/addnewchat.svg": "cb3c95af27a5c28e4b0b29af6d8ac809",
"assets/assets/images/Vitty.ai2.png": "036fc18c257d0115695dc3a818cf6ee7",
"assets/assets/images/reorder.svg": "ea6b27c1e46a75458b896e39e471d575",
"assets/assets/images/android12_native.png": "279c253a368c2ba936bde62083e8ab9e",
"assets/assets/images/edit.png": "30dc5b59a2e4506e464249f074f3ab0c",
"assets/assets/images/sort.svg": "7f70442bfbdcb850b3f4db55cc24a213",
"assets/assets/images/new_mesh.png": "3ece309283edaf26bdb24147cc90605c",
"assets/assets/images/attach.svg": "d8d4b7b90c7cafcb64d4d93c24b5b057",
"assets/assets/images/animated_mesh.gif": "e673f7c3041926645747c4e5ee1d16e7",
"assets/assets/images/ying_yang_ios.png": "92c84f05e83190fe30d193eba76b32b6",
"assets/assets/images/onboard.png": "658d7c3b3fa2f2212c944164f3859483",
"assets/assets/images/notify.svg": "ea1123d473d8c67dd8ad6b8dc379decd",
"assets/assets/images/red_mesh.png": "5a328831e2d9336d1b2358c813ddc65b",
"assets/assets/images/retry1.json": "bff473d58e71c45651c2ece9368573db",
"assets/assets/images/smoky.gif": "8137250ce34ea5b4597c09dd84e72abe",
"assets/assets/images/icon_app.png": "8e06be6e6cc7d6a3c6a6d7b6bddd7153",
"assets/assets/images/splash_logo.png": "7e124c9a5d3f1130efa9438954407fcc",
"assets/assets/images/purple.png": "4b94c5246f209b1545148d1b72ecf862",
"assets/assets/images/background_recorder.png": "d3285478c9e8251249a2f6ca55859752",
"assets/assets/images/typing_loader.json": "5df96daf250ebc5462aef8ea6f42e309",
"assets/assets/images/mic.png": "b086793afd848ab3491f864d9a4ac01c",
"assets/assets/fonts/josefin-sans/JosefinSans-Bold.ttf": "e314da2c0c4113fe575fa8a22cec8394",
"assets/assets/fonts/josefin-sans/JosefinSans-Regular.ttf": "38107321b85bfb3bfe4230fb32d6ce83",
"assets/assets/fonts/dm-sans/DMSans-Regular.ttf": "8c79e87613696cae32379ee06b2e16c7",
"assets/assets/fonts/dm-sans/DMSans-Bold.ttf": "1af8ec25074feb61fd81bc4d81d857aa",
"assets/assets/fonts/dm-sans/DMSans-Italic.ttf": "4f2f2cddd36ede927d47cdf78d352b2a",
"assets/assets/fonts/inter/Inter-Bold.otf": "d6312ef1e6c284ca5266b4be8f74056e",
"assets/assets/fonts/inter/Inter-Regular.otf": "6b39225d5fa67b3d717db7c92e88c6ad",
"canvaskit/skwasm_st.js": "d1326ceef381ad382ab492ba5d96f04d",
"canvaskit/skwasm.js": "f2ad9363618c5f62e813740099a80e63",
"canvaskit/skwasm.js.symbols": "80806576fa1056b43dd6d0b445b4b6f7",
"canvaskit/canvaskit.js.symbols": "68eb703b9a609baef8ee0e413b442f33",
"canvaskit/skwasm.wasm": "f0dfd99007f989368db17c9abeed5a49",
"canvaskit/chromium/canvaskit.js.symbols": "5a23598a2a8efd18ec3b60de5d28af8f",
"canvaskit/chromium/canvaskit.js": "34beda9f39eb7d992d46125ca868dc61",
"canvaskit/chromium/canvaskit.wasm": "64a386c87532ae52ae041d18a32a3635",
"canvaskit/skwasm_st.js.symbols": "c7e7aac7cd8b612defd62b43e3050bdd",
"canvaskit/canvaskit.js": "86e461cf471c1640fd2b461ece4589df",
"canvaskit/canvaskit.wasm": "efeeba7dcc952dae57870d4df3111fad",
"canvaskit/skwasm_st.wasm": "56c3973560dfcbf28ce47cebe40f3206"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
