#!/usr/bin/env bash
# Copyright 2021 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_ROOT}"/lib.sh

# shellcheck disable=SC1091
source "${REPO_ROOT}/hack/build/setup-go.sh"

function usage() {
  >&2 cat <<EOF
Run Prow's integration tests.

Usage: $0 [options]

Examples:
  # Bring up the KIND cluster and Prow components, but only run the
  # "TestClonerefs/postsubmit" test.
  $0 -run=Clonerefs/post

  # Only run the "TestClonerefs/postsubmit" test, with increased verbosity.
  $0 -verbose -no-setup -run=Clonerefs/post

  # Recompile and redeploy the Prow components that use the "fakegitserver" and
  # "fakegerritserver" images, then only run the "TestClonerefs/postsubmit"
  # test, but also
  $0 -verbose -build=fakegitserver,fakegerritserver -run=Clonerefs/post

  # Recompile "deck" image, redeploy "deck" and "deck-tenanted" Prow components,
  # then only run the "TestDeck" tests. The test knows that "deck" and
  # "deck-tenanted" components both depend on the "deck" image in lib.sh (grep
  # for PROW_IMAGES_TO_COMPONENTS).
  $0 -verbose -build=deck -run=Clonerefs/post

  # Recompile all Prow components, redeploy them, and then only run the
  # "TestClonerefs/postsubmit" test.
  $0 -verbose -no-setup-kind-cluster -run=Clonerefs/post

Options:
    -no-setup:
        Skip setup of the KIND cluster and Prow installation. That is, only run
        gotestsum. This is useful if you already have the cluster and components
        set up, and only want to run some tests without setting up the cluster
        or recompiling Prow images.

    -no-setup-kind-cluster:
        Skip setup of the KIND cluster, but still (re-)install Prow to the
        cluster. Flag "-build=..." implies this flag. This is useful if you want
        to skip KIND setup. Most of the time, you will want to use this flag
        when rerunning tests after initially setting up the cluster (because
        most of the time your changes will not impact the KIND cluster itself).

    -build='':
        Build only the comma-separated list of Prow components with
        "${REPO_ROOT}"/hack/prowimagebuilder. Useful when developing a fake
        service that needs frequent recompilation. The images are a
        comma-separated string. Also results in only redeploying certain entries
        in PROW_COMPONENTS, by way of PROW_IMAGES_TO_COMPONENTS in lib.sh.

        Implies -no-setup-kind-cluster.

    -run='':
        Run only those tests that match the given pattern. The format is
        "TestName/testcasename". E.g., "TestClonerefs/postsubmit" will only run
        1 test. Due to fuzzy matching, "Clonerefs/post" is equivalent.

    -save-logs='':
        Export all cluster logs to the given directory (directory will be
        created if it doesn't exist).

    -teardown:
        Delete the KIND cluster and also the local Docker registry used by the
        cluster.

    -verbose:
        Make tests run more verbosely.

    -help:
        Display this help message.
EOF
}

function main() {
  declare -a tests_to_run
  declare -a setup_args
  declare -a teardown_args
  setup_args=(-setup-kind-cluster -setup-prow-components)
  local summary_format
  summary_format=pkgname
  local setup_kind_cluster
  local setup_prow_components
  local build_images
  setup_kind_cluster=0
  setup_prow_components=0

  for arg in "$@"; do
    case "${arg}" in
      -no-setup)
        unset 'setup_args[0]'
        unset 'setup_args[1]'
        ;;
      -no-setup-kind-cluster)
        unset 'setup_args[0]'
        ;;
      -build=*)
        setup_args[0]=
        setup_args[1]="-setup-prow-components"
        setup_args+=("${arg}")
        ;;
      -run=*)
        tests_to_run+=("${arg}")
        ;;
      -save-logs=*)
        teardown_args+=("${arg}")
        ;;
      -teardown)
        teardown_args+=(-all)
        ;;
      -verbose)
        summary_format=standard-verbose
        ;;
      -help)
        usage
        return
        ;;
      --*)
        echo >&2 "cannot use flags with two leading dashes ('--...'), use single dashes instead ('-...')"
        return 1
        ;;
    esac
  done

  # If in CI (pull-test-infra-integration presubmit job), use the ARTIFACTS
  # variable to save log output.
  if [[ -n "${ARTIFACTS:-}" ]]; then
    teardown_args+=(-save-logs="${ARTIFACTS}/kind_logs")
  fi

  if [[ -n "${teardown_args[*]}" ]]; then
    # shellcheck disable=SC2064
    trap "${SCRIPT_ROOT}/teardown.sh ${teardown_args[*]}" EXIT
  fi

  for arg in "${setup_args[@]}"; do
    case "${arg}" in
      -setup-kind-cluster) setup_kind_cluster=1 ;;
      -setup-prow-components) setup_prow_components=1 ;;
      -build=*)
        build_images="${arg#-build=}"
        ;;
    esac
  done

  if ((setup_kind_cluster)); then
    "${SCRIPT_ROOT}"/setup-kind-cluster.sh
  fi

  if ((setup_prow_components)); then
    "${SCRIPT_ROOT}"/setup-prow-components.sh ${build_images:+"-build=${build_images}"}
  fi

  build_gotestsum

  log "Finished preparing environment; running integration test"

  JUNIT_RESULT_DIR="${REPO_ROOT}/_output"
  # If we are in CI, copy to the artifact upload location.
  if [[ -n "${ARTIFACTS:-}" ]]; then
    JUNIT_RESULT_DIR="${ARTIFACTS}"
  fi

  # Run integration tests with junit output.
  mkdir -p "${JUNIT_RESULT_DIR}"
  "${REPO_ROOT}/_bin/gotestsum" \
    --format "${summary_format}" \
    --junitfile="${JUNIT_RESULT_DIR}/junit-integration.xml" \
    -- "${SCRIPT_ROOT}/test" \
    --run-integration-test ${tests_to_run[@]:+"${tests_to_run[@]}"}
}

function build_gotestsum() {
  log "Building gotestsum"
  set -x
  pushd "${REPO_ROOT}/hack/tools"
  go build -o "${REPO_ROOT}/_bin/gotestsum" gotest.tools/gotestsum
  popd
  set +x
}

main "$@"
