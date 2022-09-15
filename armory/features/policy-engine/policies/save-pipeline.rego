# manual-judgment.rego. Notice the package. The opa.pipelines package is used for policies that get checked when a pipeline is saved.
package spinnaker.persistence.pipelines.before

deny["Every pipeline must have a Manual Judgment stage"] {

  1 == 0
}
