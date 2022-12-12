# Pin npm packages by running ./bin/importmap

pin 'identity', preload: true
pin 'inspect', preload: true
pin '@hotwired/turbo-rails', to: 'turbo.min.js', preload: true
pin '@hotwired/stimulus', to: 'stimulus.min.js', preload: true
pin '@hotwired/stimulus-loading', to: 'stimulus-loading.js', preload: true

pin 'local-time', to: 'https://ga.jspm.io/npm:local-time@2.1.0/app/assets/javascripts/local-time.js'
pin 'focus-trap', to: 'https://ga.jspm.io/npm:focus-trap@7.0.0/dist/focus-trap.esm.js'
pin 'hotkeys-js', to: 'https://ga.jspm.io/npm:hotkeys-js@3.10.1/dist/hotkeys.esm.js'
pin 'stimulus-use', to: 'https://ga.jspm.io/npm:stimulus-use@0.51.1/dist/index.js'
pin 'tabbable', to: 'https://ga.jspm.io/npm:tabbable@6.0.1/dist/index.esm.js'

pin_all_from 'app/javascript/controllers', under: 'controllers'
