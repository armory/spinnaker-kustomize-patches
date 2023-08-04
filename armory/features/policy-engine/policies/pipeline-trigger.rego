package spinnaker.execution.pipelines.before

#Create a list of deny messages
deny["Trigger cannot be another pipeline -- use manual"]{
   startswith(input.pipeline.name, "Pipeline-only-manual")
   input.pipeline.trigger.type == "pipeline"
}

#Return object back to spinnaker
response := {
    "allowed" : count(deny) == 0,
    "errors" : deny
}