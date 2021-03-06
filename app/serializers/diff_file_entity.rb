# frozen_string_literal: true

class DiffFileEntity < DiffFileBaseEntity
  include CommitsHelper
  include IconsHelper

  expose :too_large?, as: :too_large
  expose :empty?, as: :empty
  expose :added_lines
  expose :removed_lines

  expose :load_collapsed_diff_url, if: -> (diff_file, options) { diff_file.text? && options[:merge_request] } do |diff_file|
    merge_request = options[:merge_request]
    project = merge_request.target_project

    next unless project

    diff_for_path_namespace_project_merge_request_path(
      namespace_id: project.namespace.to_param,
      project_id: project.to_param,
      id: merge_request.iid,
      old_path: diff_file.old_path,
      new_path: diff_file.new_path,
      file_identifier: diff_file.file_identifier
    )
  end

  expose :view_path, if: -> (_, options) { options[:merge_request] } do |diff_file|
    merge_request = options[:merge_request]

    project = merge_request.target_project

    next unless project
    next unless diff_file.content_sha

    project_blob_path(project, tree_join(diff_file.content_sha, diff_file.new_path))
  end

  expose :viewer, using: DiffViewerEntity do |diff_file|
    diff_file.rich_viewer || diff_file.simple_viewer
  end

  expose :replaced_view_path, if: -> (_, options) { options[:merge_request] } do |diff_file|
    image_diff = diff_file.rich_viewer && diff_file.rich_viewer.partial_name == 'image'
    image_replaced = diff_file.old_content_sha && diff_file.old_content_sha != diff_file.content_sha

    merge_request = options[:merge_request]
    project = merge_request.target_project

    next unless project

    project_blob_path(project, tree_join(diff_file.old_content_sha, diff_file.old_path)) if image_diff && image_replaced
  end

  expose :context_lines_path, if: -> (diff_file, _) { diff_file.text? } do |diff_file|
    next unless diff_file.content_sha

    project_blob_diff_path(diff_file.repository.project, tree_join(diff_file.content_sha, diff_file.file_path))
  end

  # Used for inline diffs
  expose :highlighted_diff_lines, using: DiffLineEntity, if: -> (diff_file, _) { diff_file.text? } do |diff_file|
    diff_file.diff_lines_for_serializer
  end

  # Used for parallel diffs
  expose :parallel_diff_lines, using: DiffLineParallelEntity, if: -> (diff_file, _) { diff_file.text? }
end
