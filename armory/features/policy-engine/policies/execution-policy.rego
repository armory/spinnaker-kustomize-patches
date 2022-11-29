package spinnaker.execution.stages.before.deployManifest

deny["deployManifest cannot be run without requisite bakeManifest stage"] {
    canDeployStages := [s | s = input.pipeline.stages[_]; s.type == "bakeManifest"]
    stage := canDeployStages[_]
    not stage.context.bake == true
}
