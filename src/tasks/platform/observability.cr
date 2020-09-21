# coding: utf-8
require "sam"
require "colorize"
require "../utils/utils.cr"

namespace "platform" do
  desc "The CNF conformance suite checks to see if the Platform has Observability support."
  task "observability", ["kube_state_metrics", "node_exporter"] do |t, args|
    VERBOSE_LOGGING.info "resilience" if check_verbose(args)
    VERBOSE_LOGGING.debug "resilience args.raw: #{args.raw}" if check_verbose(args)
    VERBOSE_LOGGING.debug "resilience args.named: #{args.named}" if check_verbose(args)
    stdout_score("platform:resilience")
  end

  desc "Does the Platform have Kube State Metrics installed"
  task "kube_state_metrics" do |_, args|
    unless check_poc(args)
      LOGGING.info "skipping kube_state_metrics: not in poc mode"
      puts "Skipped".colorize(:yellow)
      next
    end
    LOGGING.info "Running POC: kube_state_metrics"
    task_response = task_runner(args) do |args|
      current_dir = FileUtils.pwd 

      state_metric_releases = `curl -L -s https://quay.io/api/v1/repository/coreos/kube-state-metrics/tag/?limit=100`
      # Get the sha hash for the kube-state-metrics container
      sha_list = named_sha_list(state_metric_releases)
      LOGGING.debug "sha_list: #{sha_list}"

      # TODO find hash for image
      imageids = KubectlClient::Get.all_container_repo_digests
      LOGGING.debug "imageids: #{imageids}"
      found = false
      release_name = ""
      sha_list.each do |x|
        if imageids.find{|i| i.includes?(x["manifest_digest"])}
          found = true
          release_name = x["name"]
        end
      end
      if found
        emoji_kube_state_metrics="📶☠️"
        upsert_passed_task("kube_state_metrics","✔️  PASSED: Your platform is using the #{release_name} release for kube state metrics #{emoji_kube_state_metrics}")
      else
        emoji_kube_state_metrics="📶☠️"
        upsert_failed_task("kube_state_metrics", "✖️  FAILURE: Your platform does not have kube state metrics installed #{emoji_kube_state_metrics}")
      end
    end
  end

  desc "Does the Platform have a Node Exporter installed"
  task "node_exporter" do |_, args|
    unless check_poc(args)
      LOGGING.info "skipping node_exporter: not in poc mode"
      puts "Skipped".colorize(:yellow)
      next
    end
    LOGGING.info "Running POC: node_exporter"
    task_response = task_runner(args) do |args|

      #Select the first node that isn't a master and is also schedulable
      #worker_nodes = `kubectl get nodes --selector='!node-role.kubernetes.io/master' -o 'go-template={{range .items}}{{$taints:=""}}{{range .spec.taints}}{{if eq .effect "NoSchedule"}}{{$taints = print $taints .key ","}}{{end}}{{end}}{{if not $taints}}{{.metadata.name}}{{ "\\n"}}{{end}}{{end}}'`
      #worker_node = worker_nodes.split("\n")[0]

      # Install and find CRI Tools name
      File.write("cri_tools.yml", CRI_TOOLS)
      install_cri_tools = `kubectl create -f cri_tools.yml`
      cri_tools_pod = CNFManager.pod_status("cri-tools").split(",")[0]
      #, "--field-selector spec.nodeName=#{worker_node}")
      LOGGING.debug "cri_tools_pod: #{cri_tools_pod}"

      # Fetch id sha256 sums for all repo_digests https://github.com/docker/distribution/issues/1662
      repo_digest_list = KubectlClient::Get.all_container_repo_digests
      LOGGING.info "container_repo_digests: #{repo_digest_list}"
      id_sha256_list = repo_digest_list.reduce([] of String) do |acc, repo_digest|
        LOGGING.debug "repo_digest: #{repo_digest}"
        cricti = `kubectl exec -ti #{cri_tools_pod} crictl inspecti #{repo_digest}`
        LOGGING.debug "cricti: #{cricti}"
        parsed_json = JSON.parse(cricti)
        acc << parsed_json["status"]["id"].as_s
      end
      LOGGING.debug "id_sha256_list: #{id_sha256_list}"


      # Fetch image id sha256sums available for all upstream node-exporter releases
      node_exporter_releases = `curl -L -s 'https://registry.hub.docker.com/v2/repositories/prom/node-exporter/tags?page_size=1024'`
      tag_list = named_sha_list(node_exporter_releases)
      LOGGING.info "tag_list: #{tag_list}"
      if ENV["DOCKERHUB_USERNAME"]? && ENV["DOCKERHUB_PASSWORD"]?
        target_ns_repo = "prom/node-exporter"
        params = "service=registry.docker.io&scope=repository:#{target_ns_repo}:pull"
        token = `curl --user "#{ENV["DOCKERHUB_USERNAME"]}:#{ENV["DOCKERHUB_PASSWORD"]}" "https://auth.docker.io/token?#{params}"`
        parsed_token = JSON.parse(token)
        release_id_list = tag_list.reduce([] of Hash(String, String)) do |acc, tag|
          LOGGING.debug "tag: #{tag}"
          tag = tag["name"]

          image_id = `curl --header "Accept: application/vnd.docker.distribution.manifest.v2+json" "https://registry-1.docker.io/v2/#{target_ns_repo}/manifests/#{tag}" -H "Authorization:Bearer #{parsed_token["token"].as_s}"`
          parsed_image = JSON.parse(image_id)

          LOGGING.debug "parsed_image config digest #{parsed_image["config"]["digest"]}"
          if parsed_image["config"]["digest"]?
              acc << {"name" => tag, "digest"=> parsed_image["config"]["digest"].as_s}
          else
            acc
          end
        end
      else
        puts "DOCKERHUB_USERNAME & DOCKERHUB_PASSWORD Must be set."
        exit 1
      end
      LOGGING.debug "Release id sha256sum list: #{release_id_list}"

      found = false
      release_name = ""
      release_id_list.each do |x|
        if id_sha256_list.find{|i| i.includes?(x["digest"])}
          found = true
          release_name = x["name"]
        end
      end
      if found
        emoji_node_exporter="📶☠️"
        upsert_passed_task("node_exporter","✔️  PASSED: Your platform is using the #{release_name} release for the node exporter #{emoji_node_exporter}")
      else
        emoji_node_exporter="📶☠️"
        upsert_failed_task("node_exporter", "✖️  FAILURE: Your platform does not have the node exporter installed #{emoji_node_exporter}")
      end
    end
  end
end

def named_sha_list(resp_json)
  LOGGING.debug "sha_list resp_json: #{resp_json}"
  parsed_json = JSON.parse(resp_json)
  LOGGING.debug "sha list parsed json: #{parsed_json}"
  #if tags then this is a quay repository, otherwise assume docker hub repository
  if parsed_json["tags"]?
    parsed_json["tags"].not_nil!.as_a.reduce([] of Hash(String, String)) do |acc, i|
      acc << {"name" => i["name"].not_nil!.as_s, "manifest_digest" => i["manifest_digest"].not_nil!.as_s}
    end
  else
    parsed_json["results"].not_nil!.as_a.reduce([] of Hash(String, String)) do |acc, i|
      #TODO always use amd64
      amd64image = i["images"].as_a.find{|x| x["architecture"].as_s == "amd64"}
      LOGGING.debug "amd64image: #{amd64image}"
      if amd64image && amd64image["digest"]?
        acc << {"name" => i["name"].not_nil!.as_s, "manifest_digest" => amd64image["digest"].not_nil!.as_s}
      else
        LOGGING.error "amd64 image not found in #{i["images"]}"
        acc
      end
    end
  end
end
