{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  serviceWorker: {
    serviceWorkerVersion: {{flutter_service_worker_version}}
  },
  onEntrypointLoaded: function(engineInitializer) {
    engineInitializer.initializeEngine({
      useColorEmoji: true,
      renderer: 'canvaskit'
    }).then(function(appRunner) {
      appRunner.runApp();
    });
  }
});