/**
 * RepoFlow 代码浏览器 - 数据模型
 * 
 * 定义文件树和代码显示所需的数据结构
 */

// =====================================================
// 文件树节点类型
// =====================================================

export enum FileNodeType {
  /** 目录 */
  DIRECTORY = 'directory',
  /** 文件 */
  FILE = 'file',
  /** 符号链接 */
  SYMLINK = 'symlink',
  /** 子模块 */
  SUBMODULE = 'submodule',
}

// =====================================================
// 文件树节点接口
// =====================================================

export interface FileTreeNode {
  /** 唯一标识 (路径) */
  path: string;
  /** 文件/目录名 */
  name: string;
  /** 节点类型 */
  type: FileNodeType;
  /** 文件扩展名 (仅文件有效) */
  extension?: string;
  /** 文件大小 (字节) */
  size?: number;
  /** 子节点 (仅目录有效) */
  children?: FileTreeNode[];
  /** 是否已加载子节点 */
  childrenLoaded?: boolean;
  /** 是否正在加载 */
  isLoading?: boolean;
  /** SHA 值 */
  sha?: string;
  /** 深度层级 */
  depth: number;
  /** 是否展开 */
  expanded?: boolean;
  /** 父节点路径 */
  parentPath?: string;
}

// =====================================================
// 扁平化的文件树节点 (用于虚拟列表)
// =====================================================

export interface FlatFileNode extends FileTreeNode {
  /** 可见性 (根据父节点展开状态) */
  visible: boolean;
  /** 在可见列表中的索引 */
  visibleIndex?: number;
}

// =====================================================
// 代码行接口
// =====================================================

export interface CodeLine {
  /** 行号 (1-based) */
  lineNumber: number;
  /** 行内容 */
  content: string;
  /** 是否选中 */
  selected?: boolean;
  /** 是否高亮 */
  highlighted?: boolean;
  /** 语法高亮后的富文本片段 */
  tokens?: CodeToken[];
}

// =====================================================
// 代码片段 (用于语法高亮)
// =====================================================

export interface CodeToken {
  /** 文本内容 */
  text: string;
  /** Token 类型 */
  type: TokenType;
  /** 起始位置 */
  start: number;
  /** 结束位置 */
  end: number;
}

// =====================================================
// Token 类型
// =====================================================

export enum TokenType {
  /** 普通文本 */
  PLAIN = 'plain',
  /** 关键字 */
  KEYWORD = 'keyword',
  /** 字符串 */
  STRING = 'string',
  /** 数字 */
  NUMBER = 'number',
  /** 注释 */
  COMMENT = 'comment',
  /** 函数名 */
  FUNCTION = 'function',
  /** 类名 */
  CLASS = 'class',
  /** 变量 */
  VARIABLE = 'variable',
  /** 操作符 */
  OPERATOR = 'operator',
  /** 标点符号 */
  PUNCTUATION = 'punctuation',
  /** 类型 */
  TYPE = 'type',
  /** 装饰器/注解 */
  DECORATOR = 'decorator',
  /** 标签 (HTML/XML) */
  TAG = 'tag',
  /** 属性 */
  ATTRIBUTE = 'attribute',
  /** 正则表达式 */
  REGEX = 'regex',
}

// =====================================================
// 行范围接口
// =====================================================

export interface LineRange {
  start: number;
  end: number;
}

// =====================================================
// 代码文件内容接口
// =====================================================

export interface FileContent {
  /** 文件路径 */
  path: string;
  /** 文件名 */
  name: string;
  /** 文件扩展名 */
  extension: string;
  /** 文件大小 */
  size: number;
  /** 行数 */
  lineCount: number;
  /** 编码 */
  encoding: string;
  /** 是否为二进制文件 */
  isBinary: boolean;
  /** 语言类型 */
  language: string;
  /** 代码行 (分页加载) */
  lines: CodeLine[];
  /** 已加载的行范围 */
  loadedRange: LineRange;
  /** 原始内容 (用于搜索等) */
  rawContent?: string;
}

// =====================================================
// 文件树状态接口
// =====================================================

export interface FileTreeState {
  /** 根节点列表 */
  roots: FileTreeNode[];
  /** 扁平化的可见节点列表 */
  flatNodes: FlatFileNode[];
  /** 展开的节点路径集合 */
  expandedPaths: Set<string>;
  /** 选中的节点路径 */
  selectedPath: string | null;
  /** 是否正在加载 */
  isLoading: boolean;
  /** 错误信息 */
  error: string | null;
}

// =====================================================
// 代码查看器状态接口
// =====================================================

export interface CodeViewerState {
  /** 当前文件内容 */
  file: FileContent | null;
  /** 是否正在加载 */
  isLoading: boolean;
  /** 错误信息 */
  error: string | null;
  /** 滚动位置 */
  scrollPosition: number;
  /** 选中的行范围 */
  selectedLines: LineRange | null;
  /** 搜索结果 */
  searchResults: number[];
  /** 当前搜索索引 */
  currentSearchIndex: number;
}

// =====================================================
// 仓库信息接口
// =====================================================

export interface RepositoryInfo {
  owner: string;
  name: string;
  branch: string;
}

// =====================================================
// 代码浏览器状态接口
// =====================================================

export interface CodeBrowserState {
  /** 仓库信息 */
  repository: RepositoryInfo;
  /** 文件树状态 */
  fileTree: FileTreeState;
  /** 代码查看器状态 */
  codeViewer: CodeViewerState;
  /** 面包屑路径 */
  breadcrumbs: string[];
  /** 历史记录 */
  history: string[];
  /** 历史索引 */
  historyIndex: number;
}

// =====================================================
// 虚拟列表配置
// =====================================================

export interface VirtualListConfig {
  /** 项目高度 (固定高度以优化性能) */
  itemHeight: number;
  /** 可视区域高度 */
  viewportHeight: number;
  /** 预渲染缓冲区大小 (上下各多渲染的行数) */
  bufferSize: number;
  /** 总项目数 */
  totalItems: number;
}

// =====================================================
// 虚拟列表状态
// =====================================================

export interface VirtualListState {
  /** 滚动偏移量 */
  scrollOffset: number;
  /** 可见起始索引 */
  visibleStartIndex: number;
  /** 可见结束索引 */
  visibleEndIndex: number;
  /** 渲染起始索引 (包含缓冲区) */
  renderStartIndex: number;
  /** 渲染结束索引 (包含缓冲区) */
  renderEndIndex: number;
}

// =====================================================
// 辅助函数
// =====================================================

/**
 * 根据文件名获取扩展名
 */
export function getFileExtension(filename: string): string {
  const lastDot = filename.lastIndexOf('.');
  if (lastDot === -1 || lastDot === 0) {
    return '';
  }
  return filename.substring(lastDot + 1).toLowerCase();
}

/**
 * 根据扩展名推断语言
 */
export function getLanguageFromExtension(extension: string): string {
  const extensionMap: Record<string, string> = {
    // JavaScript/TypeScript
    'js': 'javascript',
    'jsx': 'javascript',
    'ts': 'typescript',
    'tsx': 'typescript',
    'mjs': 'javascript',
    'cjs': 'javascript',
    'ets': 'arkts',
    
    // Web
    'html': 'html',
    'htm': 'html',
    'css': 'css',
    'scss': 'scss',
    'sass': 'sass',
    'less': 'less',
    'vue': 'vue',
    'svelte': 'svelte',
    
    // Data formats
    'json': 'json',
    'json5': 'json5',
    'yaml': 'yaml',
    'yml': 'yaml',
    'xml': 'xml',
    'toml': 'toml',
    
    // Languages
    'py': 'python',
    'java': 'java',
    'kt': 'kotlin',
    'kts': 'kotlin',
    'swift': 'swift',
    'go': 'go',
    'rs': 'rust',
    'c': 'c',
    'cpp': 'cpp',
    'h': 'c',
    'hpp': 'cpp',
    'cs': 'csharp',
    'rb': 'ruby',
    'php': 'php',
    'dart': 'dart',
    'lua': 'lua',
    'r': 'r',
    'scala': 'scala',
    'groovy': 'groovy',
    'pl': 'perl',
    'sh': 'shell',
    'bash': 'shell',
    'zsh': 'shell',
    'ps1': 'powershell',
    
    // Config/Build
    'md': 'markdown',
    'markdown': 'markdown',
    'dockerfile': 'dockerfile',
    'makefile': 'makefile',
    'gradle': 'gradle',
    'cmake': 'cmake',
    
    // Others
    'sql': 'sql',
    'graphql': 'graphql',
    'proto': 'protobuf',
    'tex': 'latex',
  };
  
  return extensionMap[extension] || 'plaintext';
}

/**
 * 格式化文件大小
 */
export function formatFileSize(bytes: number): string {
  if (bytes === 0) return '0 B';
  
  const units = ['B', 'KB', 'MB', 'GB'];
  const k = 1024;
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  
  return `${(bytes / Math.pow(k, i)).toFixed(i > 0 ? 1 : 0)} ${units[i]}`;
}

/**
 * 判断是否为二进制文件
 */
export function isBinaryExtension(extension: string): boolean {
  const binaryExtensions = [
    'png', 'jpg', 'jpeg', 'gif', 'bmp', 'ico', 'webp', 'svg',
    'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
    'zip', 'rar', '7z', 'tar', 'gz', 'bz2',
    'exe', 'dll', 'so', 'dylib', 'o', 'a',
    'mp3', 'mp4', 'avi', 'mov', 'mkv', 'wav', 'flac',
    'ttf', 'otf', 'woff', 'woff2', 'eot',
    'class', 'jar', 'war',
  ];
  
  return binaryExtensions.includes(extension.toLowerCase());
}

/**
 * 计算虚拟列表的可见范围
 */
export function calculateVisibleRange(
  config: VirtualListConfig,
  scrollOffset: number
): VirtualListState {
  const itemHeight = config.itemHeight;
  const viewportHeight = config.viewportHeight;
  const bufferSize = config.bufferSize;
  const totalItems = config.totalItems;
  
  // 计算可见范围
  const visibleStartIndex = Math.floor(scrollOffset / itemHeight);
  const visibleCount = Math.ceil(viewportHeight / itemHeight);
  const visibleEndIndex = Math.min(visibleStartIndex + visibleCount, totalItems - 1);
  
  // 添加缓冲区
  const renderStartIndex = Math.max(0, visibleStartIndex - bufferSize);
  const renderEndIndex = Math.min(totalItems - 1, visibleEndIndex + bufferSize);
  
  return {
    scrollOffset,
    visibleStartIndex,
    visibleEndIndex,
    renderStartIndex,
    renderEndIndex,
  };
}
