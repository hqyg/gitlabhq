require 'spec_helper'

describe Ci::PipelinePolicy, :models do
  let(:user) { create(:user) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project) }

  let(:policy) do
    described_class.new(user, pipeline)
  end

  describe 'rules' do
    describe 'rules for protected ref' do
      let(:project) { create(:project, :repository) }

      before do
        project.add_developer(user)
      end

      context 'when no one can push or merge to the branch' do
        before do
          create(:protected_branch, :no_one_can_push,
                 name: pipeline.ref, project: project)
        end

        it 'does not include ability to update pipeline' do
          expect(policy).to be_disallowed :update_pipeline
        end
      end

      context 'when developers can push to the branch' do
        before do
          create(:protected_branch, :developers_can_merge,
                 name: pipeline.ref, project: project)
        end

        it 'includes ability to update pipeline' do
          expect(policy).to be_allowed :update_pipeline
        end
      end

      context 'when no one can create the tag' do
        before do
          create(:protected_tag, :no_one_can_create,
                 name: pipeline.ref, project: project)

          pipeline.update(tag: true)
        end

        it 'does not include ability to update pipeline' do
          expect(policy).to be_disallowed :update_pipeline
        end
      end

      context 'when no one can create the tag but it is not a tag' do
        before do
          create(:protected_tag, :no_one_can_create,
                 name: pipeline.ref, project: project)
        end

        it 'includes ability to update pipeline' do
          expect(policy).to be_allowed :update_pipeline
        end
      end
    end

    context 'when maintainer is allowed to push to pipeline branch' do
      let(:project) { create(:project, :public) }
      let(:owner) { user }

      it 'enables update_pipeline if user is maintainer' do
        allow_any_instance_of(Project).to receive(:empty_repo?).and_return(false)
        allow_any_instance_of(Project).to receive(:branch_allows_collaboration?).and_return(true)

        expect(policy).to be_allowed :update_pipeline
      end
    end

    describe 'destroy_pipeline' do
      let(:project) { create(:project, :public) }

      context 'when user has owner access' do
        let(:user) { project.owner }

        it 'is enabled' do
          expect(policy).to be_allowed :destroy_pipeline
        end
      end

      context 'when user is not owner' do
        it 'is disabled' do
          expect(policy).not_to be_allowed :destroy_pipeline
        end
      end
    end
  end
end
