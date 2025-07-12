config :bus_cashing_system, BusCashingSystemWeb.Endpoint,
  url: [host: "example.com", port: 443],
  https: [
    port: 443,
    cipher_suite: :strong,
    keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
    certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  ],
  force_ssl: [hsts: true]
