# Make sure to do the following to generated a proper alertmanager.yml config file (used in docker compose)

1. Source env file (with Telegram creds)

    ```bash
    {
        set -o allexport
        source monitoring/alertmanager/.env
        set +o allexport
    }
    ```

2. Generate the config file

    ```bash
        envsubst < monitoring/alertmanager/alertmanager.template.yml > monitoring/alertmanager/alertmanager.yml
    ```
