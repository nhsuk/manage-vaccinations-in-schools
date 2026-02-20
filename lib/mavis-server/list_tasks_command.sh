region="eu-west-2"
env=${args[environment]}

authenticate_user

cluster_name="mavis-$env"

tasks=$(aws ecs list-tasks --region "$region" --cluster $cluster_name --query 'taskArns' --output text)

aws ecs describe-tasks \
    --cluster $cluster_name \
    --tasks $tasks \
    --query 'tasks[].{ARN: taskArn, Group: group, Status: lastStatus}' \
    --output json \
  | jq -r '(.[] | [.Group, .Status, .ARN]) | @tsv' \
  | ruby -e "cluster_name, region = ['$cluster_name', '$region']" \
         -e '
      def make_link(text, url) = "\033]8;;#{url}\033\\#{text}\033]8;;\033\\"

      def pad_field(width, text, contents) = "#{" " * (width - text.length)}#{contents}" 

      max_widths = {service: 0, status: 0, task: 0}
      rows = ARGF.each_line.map do |line|
        group, status, arn = line.strip.split("\t")
        task_id = arn.split("/").last
        task_link = make_link(task_id, "https://#{region}.console.aws.amazon.com/ecs/v2/clusters/#{cluster_name}/tasks/#{task_id}")
        service_name = group.split(":").last
        service_link = make_link(service_name, "https://#{region}.console.aws.amazon.com/ecs/v2/clusters/#{cluster_name}/services/#{service_name}")
        max_widths[:task] = [max_widths[:task], task_id.length].max
        max_widths[:service] = [max_widths[:service], service_name.length].max
        max_widths[:status] = [max_widths[:status], status.length].max
        { task: task_link, service: service_link, status:, task_id:, service_name: }
      end

      puts "#{"Service".ljust(max_widths[:service])} | #{"Status".ljust(max_widths[:task])} | #{"Task".ljust(max_widths[:status])}"
      puts "-" * (max_widths.values.sum + 6)
      rows.each do |row|
        puts [pad_field(max_widths[:service], row[:service_name], row[:service]),
              pad_field(max_widths[:task], row[:task_id], row[:task]),
              pad_field(max_widths[:status], row[:status], row[:status])].join(" | ")
      end'

