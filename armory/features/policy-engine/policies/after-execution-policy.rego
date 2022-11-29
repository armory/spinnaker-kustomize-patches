package spinnaker.execution.stages.after.deployManifest

deny["deployManifest cannot be run without requisite bakeManifest stage"] {
    0 == 1
}
