#!/usr/bin/env bash

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

    export AWK_SVC_BLOCK="$service_yaml"
    export AWK_VOL_BLOCK="$volume_yaml"

    local current_content; current_content=$(cat "$compose")
    local processed_content

    if echo "$current_content" | grep -qE '^services:'; then
        # If services: key exists, inject the block under it
        processed_content=$(echo "$current_content" | awk -v name="$service_name" '
            BEGIN { svc_block = ENVIRON["AWK_SVC_BLOCK"] }
            /^services:/ { print; in_s=1; next }
            in_s && /^[^[:space:]]/ { if (!ins) { print "  # --- Service: "name" ---"; print svc_block; ins=1 } in_s=0 }
            { print }
            END { if(in_s && !ins) { print "  # --- Service: "name" ---"; print svc_block } }
        ')
    else
        # If no services: key, add it to the end
        processed_content=$(printf '%s\nservices:\n%s\n' "$current_content" "$service_yaml")
    fi

    if [ -n "$volume_yaml" ]; then
        if echo "$processed_content" | grep -qE '^volumes:'; then
            # If volumes: key exists, inject under it
            processed_content=$(echo "$processed_content" | awk '
                BEGIN { vol_block = ENVIRON["AWK_VOL_BLOCK"] }
                /^volumes:/ { print; in_v=1; next }
                in_v && /^[^[:space:]]/ { if (!ins) { print vol_block; ins=1 } in_v=0 }
                { print }
                END { if(in_v && !ins) { print vol_block } }
            ')
        else
            # If no volumes: key, add it before networks: or at the very end
            if echo "$processed_content" | grep -qE '^networks:'; then
                processed_content=$(echo "$processed_content" | awk '
                    BEGIN { vol_block = ENVIRON["AWK_VOL_BLOCK"] }
                    /^networks:/ && !done { print "volumes:"; print vol_block; print ""; done=1 }
                    { print }
                ')
            else
                processed_content=$(printf '%s\n\nvolumes:\n%s\n' "$processed_content" "$volume_yaml")
            fi
        fi
    fi

    # TODO: handle networks if needed

    echo "$processed_content" > "$compose"

    unset AWK_SVC_BLOCK
    unset AWK_VOL_BLOCK
}
