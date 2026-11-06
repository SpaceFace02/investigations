for tag in ec.11 ec.12 ec.13 ec.14 ec.15 ec.16 ec.17 ec.18 ec.19; do
  echo "=== Checking 4.21.0-okd-scos.$tag ==="
  CVO_IMAGE=$(oc adm release info quay.io/okd/scos-release:4.21.0-okd-scos.$tag --image-for=cluster-version-operator 2>/dev/null)
  if [ -n "$CVO_IMAGE" ]; then
    podman run --rm --entrypoint cluster-version-operator "$CVO_IMAGE" render --help 2>&1 | grep -q "cluster-version-manifest-path" && echo "SUPPORTED" || echo "NOT SUPPORTED"
  else
    echo "TAG NOT FOUND"
  fi
done