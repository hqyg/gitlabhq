<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { GlTooltipDirective, GlLink, GlButton } from '@gitlab/ui';
import { __ } from '~/locale';
import { polyfillSticky } from '~/lib/utils/sticky';
import Icon from '~/vue_shared/components/icon.vue';
import CompareVersionsDropdown from './compare_versions_dropdown.vue';
import SettingsDropdown from './settings_dropdown.vue';

export default {
  components: {
    CompareVersionsDropdown,
    Icon,
    GlLink,
    GlButton,
    SettingsDropdown,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    mergeRequestDiffs: {
      type: Array,
      required: true,
    },
    mergeRequestDiff: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    targetBranch: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    ...mapState('diffs', ['commit', 'showTreeList', 'startVersion', 'latestVersionPath']),
    ...mapGetters('diffs', ['hasCollapsedFile']),
    comparableDiffs() {
      return this.mergeRequestDiffs.slice(1);
    },
    showDropdowns() {
      return !this.commit && this.mergeRequestDiffs.length;
    },
    fileTreeIcon() {
      return this.showTreeList ? 'collapse-left' : 'expand-left';
    },
    toggleFileBrowserTitle() {
      return this.showTreeList ? __('Hide file browser') : __('Show file browser');
    },
    baseVersionPath() {
      return this.mergeRequestDiff.base_version_path;
    },
  },
  mounted() {
    polyfillSticky(this.$el);
  },
  methods: {
    ...mapActions('diffs', [
      'setInlineDiffViewType',
      'setParallelDiffViewType',
      'expandAllFiles',
      'toggleShowTreeList',
    ]),
  },
};
</script>

<template>
  <div class="mr-version-controls" :class="{ 'is-fileTreeOpen': showTreeList }">
    <div class="mr-version-menus-container content-block">
      <button
        v-gl-tooltip.hover
        type="button"
        class="btn btn-default append-right-8 js-toggle-tree-list"
        :class="{
          active: showTreeList,
        }"
        :title="toggleFileBrowserTitle"
        @click="toggleShowTreeList"
      >
        <icon :name="fileTreeIcon" />
      </button>
      <div v-if="showDropdowns" class="d-flex align-items-center compare-versions-container">
        Changes between
        <compare-versions-dropdown
          :other-versions="mergeRequestDiffs"
          :merge-request-version="mergeRequestDiff"
          :show-commit-count="true"
          class="mr-version-dropdown"
        />
        and
        <compare-versions-dropdown
          :other-versions="comparableDiffs"
          :base-version-path="baseVersionPath"
          :start-version="startVersion"
          :target-branch="targetBranch"
          class="mr-version-compare-dropdown"
        />
      </div>
      <div v-else-if="commit">
        {{ __('Viewing commit') }}
        <gl-link :href="commit.commit_url" class="monospace">{{ commit.short_id }}</gl-link>
      </div>
      <div class="inline-parallel-buttons d-none d-md-flex ml-auto">
        <gl-button
          v-if="commit || startVersion"
          :href="latestVersionPath"
          class="append-right-8 js-latest-version"
        >
          {{ __('Show latest version') }}
        </gl-button>
        <a v-show="hasCollapsedFile" class="btn btn-default append-right-8" @click="expandAllFiles">
          {{ __('Expand all') }}
        </a>
        <settings-dropdown />
      </div>
    </div>
  </div>
</template>
