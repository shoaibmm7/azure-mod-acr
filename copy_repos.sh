container="$(cat containername.txt)"
pass="$(cat containerpassword.txt)"

echo "Authenticating Crane"
crane auth login "${container}.azurecr.io" -u "${container}" -p "${pass}"
echo "Authenticating Helm"
helm registry login "${container}.azurecr.io" -u "${container}" -p "${pass}"

# shellcheck disable=SC2013
while IFS="," read -r imageName repoURL || [ -n "${imageName}" ]; do
  repo="${imageName%%/*}"
  app="${imageName#*/}"

  # Adding & updating help repo
  echo "Adding helm repo: ${repo}..."
  helm repo add "${repo}" "${repoURL}"
  echo "Updating helm repo: ${repo}..."
  helm repo update "${repo}"

  # Setting App and Chart versions
  chartVersion=$(helm search repo "${repo}" | grep "${imageName}" | awk '{print $2; exit}')

  # Pulling helm chart
  echo "Pulling helm chart: ${imageName}..."
  helm pull "${imageName}"
  sleep 5
  tar -xzvf "${app}"*.tgz
  sleep 5

  # Setting imageVersion according to the provider of the image
  if [[ "${repo}" == "hashicorp" ]]; then
    imageVersion=$(cat "${app}"*/values.yaml | yq '.server.image.tag')
  elif [[ "${repo}" == "jfrog" || "${repo}" == "jenkins" || "${repo}" == "jetstack" || "${repo}" == "kubereboot" || "${repo}" == "linkerd" ]]; then
    imageVersion=$(helm search repo "${repo}" | grep "${imageName}" | awk '{print $3; exit}')
  elif [[ "${repo}" == "velero" || "${repo}" == "ingress-nginx" || "${repo}" == "aad-pod-identity" ]]; then
    imageVersion="v$(helm search repo "${repo}" | grep "${imageName}" | awk '{print $3; exit}')"
  elif [[ "${repo}" == "hivemq" ]]; then
    imageNameAndVersion=$(cat "${app}"*/values.yaml | yq '.operator.image')
    imageVersion="${imageNameAndVersion#*:}"
  elif [[ "${repo}" == "bitnami" ]]; then
    imageVersion=$(cat "${app}"*/values.yaml | yq '.image.tag')
  fi
  echo "${imageName} Image version = ${imageVersion}"
  echo "${imageName} Chart version = ${chartVersion}"

  # Pushing helm chart
  echo "Pushing helm chart ${imageName} version ${chartVersion} to ${container}"
  helm push "${app}"*.tgz "oci://${container}.azurecr.io/helm"

  # Copying image using Crane
  echo "Copying image ${imageName}:${imageVersion} to ${container} and adding ${chartVersion} tag version to it..."
  if [[ "${repo}" == "jfrog" ]]; then
    imageSource="releases-docker.jfrog.io/"
    if [[ "${app}" == "artifactory-ha" ]]; then
      imageNamePro=$(cat "${app}"*/values.yaml | yq '.artifactory.image.repository')
      crane copy "${imageSource}${imageNamePro}:${imageVersion}" "${container}.azurecr.io/image/${imageName}:${imageVersion}-helm-${chartVersion}"
    elif [[ "${app}" == "xray" ]]; then
      while read -r xrayImage || [ -n "${xrayImage}" ]; do
        imageVersion=$(helm search repo "${repo}" | grep "${imageName}" | awk '{print $3; exit}')
        if [[ "${xrayImage}" == "jfrog/router" || "${xrayImage}" == "jfrog/observability" || "${xrayImage}" == "bitnami/rabbitmq" ]]; then
          imageVersion=$(cat "${app}"*/values.yaml | yq ".${xrayImage#*/}.image.tag")
          crane copy "${imageSource}${xrayImage}:${imageVersion}" "${container}.azurecr.io/image/${imageName}/${xrayImage#*/}:${imageVersion}-helm-${chartVersion}"
        else
          crane copy "${imageSource}${xrayImage}:${imageVersion}" "${container}.azurecr.io/image/${repo}/${xrayImage#*/}:${imageVersion}-helm-${chartVersion}"
        fi
      done < xray-images.csv
    fi
  elif [[ "${repo}" == "jetstack" ]]; then
    crane copy "quay.io/${imageName}-controller:${imageVersion}" "${container}.azurecr.io/image/${imageName}:${imageVersion}-helm-${chartVersion}"
  elif [[ "${repo}" == "ingress-nginx" ]]; then
    crane copy "registry.k8s.io/${app}/controller:${imageVersion}" "${container}.azurecr.io/image/${imageName}:${imageVersion}-helm-${chartVersion}"
  elif [[ "${repo}" == "kubereboot" ]]; then
    crane copy "ghcr.io/${imageName}:${imageVersion}" "${container}.azurecr.io/image/${imageName}:${imageVersion}-helm-${chartVersion}"
  elif [[ "${repo}" == "linkerd" ]]; then
    crane copy "cr.l5d.io/${repo}/controller:${imageVersion}" "${container}.azurecr.io/image/${imageName}:${imageVersion}-helm-${chartVersion}"
  elif [[ "${repo}" == "aad-pod-identity" ]]; then
    crane copy "mcr.microsoft.com/oss/azure/${app}/mic:${imageVersion}" "${container}.azurecr.io/image/${imageName}:${imageVersion}-helm-${chartVersion}"
  else
    crane copy "${imageName}:${imageVersion}" "${container}.azurecr.io/image/${imageName}:${imageVersion}-helm-${chartVersion}"
  fi
done < images.csv
