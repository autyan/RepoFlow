/**
 * RepoFlow 组件库统一导出
 * 
 * 导出所有可复用的UI组件、布局组件和功能组件
 */

// UI 基础组件
export {
  ButtonVariant,
  ButtonSize,
  RFButton,
  RFIconButton,
  CardVariant,
  RFCard,
  RFCardWithHeader,
  RFListCard,
  AvatarSizeType,
  AvatarShape,
  StatusType,
  RFAvatar,
  RFAvatarGroup,
  BadgeType,
  BadgeColor,
  BadgeSize,
  RFBadge,
  RFBadgeWrapper,
  RFLabel,
  InputType,
  InputSize,
  RFInput,
  RFTextArea,
  RFSearchInput,
} from './ui/index';

// 布局组件
export {
  NavItem,
  RFBottomTabBar,
  RFSideNavIcon,
  RFSideNavExpanded,
  RFAdaptiveNavigation,
  RFResponsiveContainer,
  RFSplitView,
  RFMasterDetail,
  RFGrid,
  RFPageHeader,
  RFScrollView,
} from './layout/index';

// 代码浏览组件
export {
  FileNodeType,
  FileTreeNode,
  FlatFileNode,
  CodeLine,
  CodeToken,
  TokenType,
  FileContent,
  FileTreeState,
  CodeViewerState,
  CodeBrowserState,
  VirtualListConfig,
  VirtualListState,
  getFileExtension,
  getLanguageFromExtension,
  formatFileSize,
  isBinaryExtension,
  calculateVisibleRange,
  VirtualListItem,
  RFVirtualList,
  RFVirtualTree,
  FileTreeItem,
  RFFileTree,
  FileTreeManager,
  CodeLineView,
  RFCodeViewer,
  CodeViewerHeader,
  CodeParser,
  Breadcrumbs,
  RFCodeBrowser,
} from './code/index';

// 编辑器组件
export {
  MarkdownNodeType,
  MarkdownNode,
  EditorMode,
  ToolbarAction,
  EditorSelection,
  EditorState,
  getMarkdownSyntax,
  detectLineType,
  parseInlineMarkdown,
  MarkdownParser,
  MarkdownNodeView,
  RFMarkdownPreview,
  RFMarkdownEditor,
  RFMarkdownViewer,
  RFCommentEditor,
} from './editor/index';
