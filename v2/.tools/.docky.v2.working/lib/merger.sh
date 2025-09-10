#!/usr/bin/env bash

# Requires functions from utils.sh (have_yq, info, warn)

merge_with_yq() {
  local compose="$1" service_yaml="$2" volume_yaml="$3"
  local tmp_add tmp_out
  tmp_add="$(mktemp)"; tmp_out="$(mktemp)"
  cat > "$tmp_add" <<EOF
services:
${service_yaml}

volumes:
${volume_yaml}
EOF
  yq eval-all 'select(fileIndex==0) *+ select(fileIndex==1)' "$compose" "$tmp_add" > "$tmp_out"
  mv "$tmp_out" "$compose"
  rm -f "$tmp_add"
}

compose_has_service() {
  local compose="$1" svc="$2"
  if have_yq; then
    yq -e ".services | has(\"$svc\")" "$compose" >/dev/null 2>&1
  else
    awk -v s="$svc" '
      $0 ~ /^services:/ { in=1; next }
      in && $0 ~ /^[^[:space:]]/ { in=0 }
      in && $0 ~ "^[[:space:]]+"s":" { found=1 }
      END { exit(found?0:1) }
    ' "$compose"
  fi
}

merge_without_yq() {
  local compose="$1" service_name="$2" service_yaml="$3" volume_yaml="$4"
  local tmp; tmp="$(mktemp)"
  # --- Inject services ---
  if grep -qE '^services:' "$compose"; then
    awk -v svc_block="$service_yaml" -v name="$service_name" '
      /^services:/ { print; in_s=1; next }
      in_s && /^[^[:space:]]/ { if (!ins){print "  # --- Service: "name" ---"; print svc_block; ins=1} in_s=0 }
      { print }
      END { if(in_s && !ins){print "  # --- Service: "name" ---"; print svc_block} }
    ' "$compose" > "$tmp"
    mv "$tmp" "$compose"
  else
    { echo "services:"; printf '%s\n' "$service_yaml"; } >> "$compose"
  fi
  # --- Inject volumes ---
  if [ -n "$volume_yaml" ]; then
    if grep -qE '^volumes:' "$compose"; then
      awk -v vol_block="$volume_yaml" '
        /^volumes:/ { print; in_v=1; next }
        in_v && /^[^[:space:]]/ { if (!ins){print vol_block; ins=1} in_v=0 }
        { print }
        END { if(in_v && !ins){ print vol_block } }
      ' "$compose" > "$tmp"
      mv "$tmp" "$compose"
    else
      if grep -qE '^networks:' "$compose"; then
        awk -v vol_block="$volume_yaml" '
          /^networks:/ && !done { print "volumes:"; print vol_block; done=1 }
          { print }
        ' "$compose" > "$tmp"
        mv "$tmp" "$compose"
      else
        { echo ""; echo "volumes:"; printf '%s\n' "$volume_yaml"; } >> "$compose"
      fi
    fi
  fi
}
