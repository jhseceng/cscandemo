#!/bin/bash
DG="\033[1;30m"
RD="\033[0;31m"
NC="\033[0;0m"
LB="\033[1;34m"
env_up() {
  echo -e "$LB\n"
  echo -e "Initializing environment templates$NC"

  # Workaround https://github.com/hashicorp/terraform-provider-google/issues/6782
  sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1 net.ipv6.conf.default.disable_ipv6=1 net.ipv6.conf.lo.disable_ipv6=1 >/dev/null
  export APIS="googleapis.com www.googleapis.com storage.googleapis.com iam.googleapis.com container.googleapis.com cloudresourcemanager.googleapis.com"
  for name in $APIS; do
    ipv4=$(getent ahostsv4 "$name" | head -n 1 | awk '{ print $1 }')
    grep -q "$name" /etc/hosts || ([ -n "$ipv4" ] && sudo sh -c "echo '$ipv4 $name' >> /etc/hosts")
  done
  # Workaround end

  set -e -o pipefail

  if [ -z "$(gcloud config get-value project 2>/dev/null)" ]; then
    project_ids=$(gcloud projects list --format json | jq -r '.[].projectId')
    project_count=$(wc -w <<<"$project_ids")
    if [ "$project_count" == "1" ]; then
      gcloud config set project "$project_ids"
    else
      gcloud projects list
      echo "Multiple pre-existing GCP projects found. Please select project using the following command before re-trying"
      echo "  gcloud config set project VALUE"
      exit 1
    fi
  fi
  export TF_VAR_project_id=$(gcloud config get-value project 2>/dev/null)
  gcloud services enable containerregistry.googleapis.com

  [ -d ~/cloud-gcp ] || (cd "$HOME" && git clone --depth 1 https://github.com/crowdstrike/cloud-gcp)
  [ -d ~/falcon-container-terraform ] || (ln -s $HOME/cloud-gcp/falcon-container-terraform $HOME/falcon-container-terraform)
  cd ~/falcon-container-terraform
  terraform init
  echo -e "$LB\n"
  echo -e "Standing up environment$NC"
  terraform apply -compact-warnings \
    -var falcon_client_id="$CLIENT_ID" -var falcon_client_secret="$CLIENT_SECRET" \
    -var falcon_cid="$CLIENT_CID" \
    -var project_id="$TF_VAR_project_id" -var falcon_cloud="us-1" --auto-approve

  cat <<__END__

                 _ _
                (_) |             Your kubernetes cluster,
  __      ____ _ _| |_            Your admin vm,
  \ \ /\ / / _\` | | __|           Your Falcon Container Sensor,
   \ V  V / (_| | | |_            and Your vulnerable application,
    \_/\_/ \__,_|_|\__|           are all comming up.


__END__
  sleep 10
  all_done
}
env_down() {
  echo -e "$RD\n"
  echo -e "Tearing down environment$NC"
  terraform -chdir=terraform destroy -var falcon_client_cid="" -var falcon_client_id="" \
    -var falcon_client_secret="" -compact-warnings --auto-approve
  env_destroyed
}
help() {
  echo "./demo {up|down|init|output|help}"
}
all_done() {
  echo -e "$LB"
  echo '  __                        _'
  echo ' /\_\/                   o | |             |'
  echo '|    | _  _  _    _  _     | |          ,  |'
  echo '|    |/ |/ |/ |  / |/ |  | |/ \_|   |  / \_|'
  echo ' \__/   |  |  |_/  |  |_/|_/\_/  \_/|_/ \/ o'
  echo -e "$NC"
}
env_destroyed() {
  echo -e "$RD"
  echo ' ___                              __,'
  echo '(|  \  _  , _|_  ,_        o     /  |           __|_ |'
  echo ' |   ||/ / \_|  /  | |  |  |    |   |  /|/|/|  |/ |  |'
  echo '(\__/ |_/ \/ |_/   |/ \/|_/|/    \_/\_/ | | |_/|_/|_/o'
  echo -e "$NC"
}
if [ -z $1 ]; then
  echo "You must specify an action."
  help
  exit 1
fi
if [[ "$1" == "up" || "$1" == "reload" ]]; then
  for arg in "$@"; do
    if [[ "$arg" == *--client_id=* ]]; then
      CLIENT_ID=${arg/--client_id=/}
    fi
    if [[ "$arg" == *--client_secret=* ]]; then
      CLIENT_SECRET=${arg/--client_secret=/}
    fi
    if [[ "$arg" == *--client_cid=* ]]; then
      CLIENT_CID=${arg/--client_cid=/}
    fi
    if [[ "$arg" == *--project_id=* ]]; then
      PROJECT_ID=${arg/--project_id=/}
    fi
    if [[ "$arg" == *--cloud=* ]]; then
      FALCON_CLOUD="${arg/--cloud=/}"
    fi
  done
  if [ -z "$CLIENT_ID" ]; then
    read -p "Falcon API Client ID: " CLIENT_ID
  fi
  if [ -z "$CLIENT_SECRET" ]; then
    read -p "Falcon API Client SECRET: " CLIENT_SECRET
  fi
  if [ -z "$CLIENT_CID" ]; then
    read -p "Falcon API Client CCID: " CLIENT_CID
  fi
  if [ -z "$PROJECT_ID" ]; then
    read -p "Google Project ID: " PROJECT_ID
  fi
  if [ -z "$FALCON_CLOUD" ]; then
    read -p "Variable falcon_cloud must be set to one of: us-1, us-2, eu-1, us-gov-1." FALCON_CLOUD
  fi
fi
if [[ "$1" == "up" ]]; then
  env_up
elif [[ "$1" == "down" ]]; then
  env_down
elif [[ "$1" == "help" ]]; then
  help
elif [[ "$1" == "output" ]]; then
  terraform -chdir=terraform output
else
  echo "Invalid action specified"
fi
