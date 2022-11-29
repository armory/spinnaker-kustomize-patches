package spinnaker.http.authz

default allow = true

allow {
    input.user.isAdmin == false
}
