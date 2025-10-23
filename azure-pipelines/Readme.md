# Notes

## General

1. AWS pipelines use stored long-lived credentials ($HOME/.aws/credentials)

2. Webhook URL for 'Terraform Applied' event:

    ```bash
    https://dev.azure.com/alakaganaguathoork/_apis/public/distributedtask/webhooks/TerraformApplied?api-version=6.0-preview
    ```

3. Validate final YAML with:

    ```bash
    az pipelines validate --pipeline-path azure-pipelines/pipeline.yml
    ```

    ```bash
        # PAT must have 'Build (Read & Execute)'
    ORG=yourorg PROJECT=yourproj PIPELINE_ID=123 PAT=xxxx
    curl -sS -u :$PAT \
      -H "Content-Type: application/json" \
      -X POST \
      "https://dev.azure.com/$ORG/$PROJECT/_apis/pipelines/$PIPELINE_ID/preview?api-version=7.1" \
      -d '{ "resources": { "repositories": { "self": { "refName": "refs/heads/feature/x" } } } }'
    # Response includes: "finalYaml": "..." (your fully expanded pipeline)
    ```

## Variables references

### Set variable

```bash
echo "##vso[task.setvariable variable=MyVar;]MyValue"
```

### Reference variable

* Refer to stage dependecy:

    ```yaml
    $[ stageDependencies.One.A.outputs['ProduceVar.MyVar'] ]
    ```

* Refer to job dependency:

    ```yaml
    $[ dependencies.CompileJob.outputs['CompileJob.CompileVar'] ]
    ```

* Refer to previous step in the same job:

    ```yaml
    $[ steps.CompileStep.outputs['CompileStep.StepVar'] ]
    ```

* Refer to previous step in the same job (alternative syntax):

    ```yaml
    $(CompileStep.StepVar)
    ```

* Refer to previous step in the same job (alternative syntax for bash script):

    ```yaml
    ${CompileStep.StepVar}
    ```

* Refer to variable defined in the same job:

    ```yaml
    $(CompileVar)
    ```

* Refer to variable defined in the same stage:

    ```yaml
    $(StageVar)
    ```
