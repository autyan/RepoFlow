/**
 * RepoFlow 颜色系统
 * 基于 design/themes.md 规范
 * 
 * 完整的暗色/亮色双主题配色方案
 */

// =====================================================
// 颜色接口定义
// =====================================================

/**
 * 主题颜色接口
 */
export interface ThemeColors {
  // 背景色
  bgPrimary: string;
  bgSecondary: string;
  bgTertiary: string;
  bgHover: string;
  
  // 背景色别名 (便于使用)
  background: string;
  surface: string;
  surfaceVariant: string;
  surfaceElevated: string;
  
  // 文本色
  textPrimary: string;
  textSecondary: string;
  textTertiary: string;
  textDisabled: string;
  textOnBrand: string;
  
  // 品牌色
  brandPrimary: string;
  brandSecondary: string;
  brandHover: string;
  brandActive: string;
  
  // 品牌色别名
  primary: string;
  primaryContainer: string;
  onPrimary: string;
  
  // 功能色
  success: string;
  successLight: string;
  successBg: string;
  warning: string;
  warningLight: string;
  warningBg: string;
  error: string;
  errorLight: string;
  errorBg: string;
  info: string;
  infoLight: string;
  infoBg: string;
  
  // GitHub 语义色
  githubOpen: string;
  githubClosed: string;
  githubMerged: string;
  githubDraft: string;
  githubSuccess: string;
  githubFailure: string;
  githubPending: string;
  
  // 边框色
  borderPrimary: string;
  borderSecondary: string;
  borderFocus: string;
  divider: string;
  border: string;
  
  // 覆盖层
  overlayLight: string;
  overlayMedium: string;
  overlayHeavy: string;
  
  // 代码语法高亮
  codeBackground: string;
  codeComment: string;
  codeKeyword: string;
  codeString: string;
  codeFunction: string;
  codeVariable: string;
  codeNumber: string;
  codeOperator: string;
  
  // 语法高亮别名
  syntaxKeyword: string;
  syntaxString: string;
  syntaxNumber: string;
  syntaxComment: string;
  syntaxFunction: string;
  
  // 文件类型颜色
  folderColor: string;
  fileDefault: string;
}

// =====================================================
// 暗色主题 (Dark Theme) - 默认主题
// OLED 优化，使用纯黑背景节省电量
// =====================================================
export const DarkColors: ThemeColors = {
  // 背景色 - OLED 纯黑优化
  bgPrimary: '#000000',
  bgSecondary: '#0F172A',
  bgTertiary: '#1E293B',
  bgHover: '#334155',
  
  // 背景色别名
  background: '#000000',
  surface: '#0F172A',
  surfaceVariant: '#1E293B',
  surfaceElevated: '#1E293B',
  
  // 文本色
  textPrimary: '#F8FAFC',
  textSecondary: '#E2E8F0',
  textTertiary: '#94A3B8',
  textDisabled: '#64748B',
  textOnBrand: '#FFFFFF',
  
  // 品牌色 - GitHub 风格蓝色
  brandPrimary: '#3B82F6',
  brandSecondary: '#2563EB',
  brandHover: '#60A5FA',
  brandActive: '#1D4ED8',
  
  // 品牌色别名
  primary: '#3B82F6',
  primaryContainer: 'rgba(59, 130, 246, 0.15)',
  onPrimary: '#FFFFFF',
  
  // 功能色
  success: '#10B981',
  successLight: '#34D399',
  successBg: 'rgba(16, 185, 129, 0.15)',
  warning: '#F59E0B',
  warningLight: '#FBBF24',
  warningBg: 'rgba(245, 158, 11, 0.15)',
  error: '#EF4444',
  errorLight: '#F87171',
  errorBg: 'rgba(239, 68, 68, 0.15)',
  info: '#3B82F6',
  infoLight: '#60A5FA',
  infoBg: 'rgba(59, 130, 246, 0.15)',
  
  // GitHub 语义色
  githubOpen: '#10B981',
  githubClosed: '#6B7280',
  githubMerged: '#8B5CF6',
  githubDraft: '#64748B',
  githubSuccess: '#10B981',
  githubFailure: '#EF4444',
  githubPending: '#F59E0B',
  
  // 边框色
  borderPrimary: '#334155',
  borderSecondary: '#475569',
  borderFocus: '#3B82F6',
  divider: '#1E293B',
  border: '#334155',
  
  // 覆盖层
  overlayLight: 'rgba(0, 0, 0, 0.4)',
  overlayMedium: 'rgba(0, 0, 0, 0.7)',
  overlayHeavy: 'rgba(0, 0, 0, 0.9)',
  
  // 代码语法高亮 (GitHub Dark 风格)
  codeBackground: '#0D1117',
  codeComment: '#8B949E',
  codeKeyword: '#FF7B72',
  codeString: '#A5D6FF',
  codeFunction: '#D2A8FF',
  codeVariable: '#FFA657',
  codeNumber: '#79C0FF',
  codeOperator: '#FF7B72',
  
  // 语法高亮别名
  syntaxKeyword: '#FF7B72',
  syntaxString: '#A5D6FF',
  syntaxNumber: '#79C0FF',
  syntaxComment: '#8B949E',
  syntaxFunction: '#D2A8FF',
  
  // 文件类型颜色
  folderColor: '#54AEFF',
  fileDefault: '#8B949E',
};

// =====================================================
// 亮色主题 (Light Theme)
// =====================================================
export const LightColors: ThemeColors = {
  // 背景色
  bgPrimary: '#FFFFFF',
  bgSecondary: '#F8FAFC',
  bgTertiary: '#F1F5F9',
  bgHover: '#E2E8F0',
  
  // 背景色别名
  background: '#FFFFFF',
  surface: '#F8FAFC',
  surfaceVariant: '#F1F5F9',
  surfaceElevated: '#FFFFFF',
  
  // 文本色
  textPrimary: '#0F172A',
  textSecondary: '#475569',
  textTertiary: '#64748B',
  textDisabled: '#94A3B8',
  textOnBrand: '#FFFFFF',
  
  // 品牌色 - 保持一致
  brandPrimary: '#3B82F6',
  brandSecondary: '#2563EB',
  brandHover: '#60A5FA',
  brandActive: '#1D4ED8',
  
  // 品牌色别名
  primary: '#3B82F6',
  primaryContainer: 'rgba(59, 130, 246, 0.1)',
  onPrimary: '#FFFFFF',
  
  // 功能色
  success: '#10B981',
  successLight: '#6EE7B7',
  successBg: 'rgba(16, 185, 129, 0.1)',
  warning: '#F59E0B',
  warningLight: '#FCD34D',
  warningBg: 'rgba(245, 158, 11, 0.1)',
  error: '#EF4444',
  errorLight: '#FCA5A5',
  errorBg: 'rgba(239, 68, 68, 0.1)',
  info: '#3B82F6',
  infoLight: '#93C5FD',
  infoBg: 'rgba(59, 130, 246, 0.1)',
  
  // GitHub 语义色 - 保持一致
  githubOpen: '#10B981',
  githubClosed: '#6B7280',
  githubMerged: '#8B5CF6',
  githubDraft: '#64748B',
  githubSuccess: '#10B981',
  githubFailure: '#EF4444',
  githubPending: '#F59E0B',
  
  // 边框色
  borderPrimary: '#E2E8F0',
  borderSecondary: '#CBD5E1',
  borderFocus: '#3B82F6',
  divider: '#E2E8F0',
  border: '#E2E8F0',
  
  // 覆盖层
  overlayLight: 'rgba(15, 23, 42, 0.1)',
  overlayMedium: 'rgba(15, 23, 42, 0.4)',
  overlayHeavy: 'rgba(15, 23, 42, 0.7)',
  
  // 代码语法高亮 (GitHub Light 风格)
  codeBackground: '#F6F8FA',
  codeComment: '#6A737D',
  codeKeyword: '#D73A49',
  codeString: '#032F62',
  codeFunction: '#6F42C1',
  codeVariable: '#E36209',
  codeNumber: '#005CC5',
  codeOperator: '#D73A49',
  
  // 语法高亮别名
  syntaxKeyword: '#D73A49',
  syntaxString: '#032F62',
  syntaxNumber: '#005CC5',
  syntaxComment: '#6A737D',
  syntaxFunction: '#6F42C1',
  
  // 文件类型颜色
  folderColor: '#54AEFF',
  fileDefault: '#57606A',
};

// =====================================================
// 文件类型颜色映射 (语言特定)
// =====================================================
export const LanguageColors: Record<string, string> = {
  // JavaScript / TypeScript
  'ts': '#3178C6',
  'tsx': '#3178C6',
  'js': '#F7DF1E',
  'jsx': '#61DAFB',
  'ets': '#3178C6',
  
  // Python
  'py': '#3776AB',
  
  // Java / Kotlin
  'java': '#B07219',
  'kt': '#A97BFF',
  
  // C / C++
  'c': '#555555',
  'cpp': '#F34B7D',
  'h': '#555555',
  'hpp': '#F34B7D',
  
  // Go / Rust
  'go': '#00ADD8',
  'rs': '#DEA584',
  
  // Web
  'html': '#E34C26',
  'css': '#563D7C',
  'scss': '#C6538C',
  'less': '#1D365D',
  'vue': '#4FC08D',
  'svelte': '#FF3E00',
  
  // Swift / Objective-C
  'swift': '#FA7343',
  'm': '#438EFF',
  
  // Ruby / PHP
  'rb': '#CC342D',
  'php': '#777BB4',
  
  // C#
  'cs': '#239120',
  
  // Shell
  'sh': '#89E051',
  'bash': '#89E051',
  'zsh': '#89E051',
  'bat': '#C1F12E',
  'ps1': '#012456',
  
  // Data / Config
  'json': '#292929',
  'yaml': '#CB171E',
  'yml': '#CB171E',
  'xml': '#E34C26',
  'toml': '#9C4221',
  
  // Documentation
  'md': '#083FA1',
  'mdx': '#083FA1',
  'txt': '#6A737D',
  'rst': '#141414',
  
  // SQL
  'sql': '#E38C00',
  
  // Dart / Flutter
  'dart': '#00B4AB',
  
  // Lua
  'lua': '#000080',
  
  // R
  'r': '#198CE7',
  
  // Scala
  'scala': '#C22D40',
  
  // Elixir / Erlang
  'ex': '#6E4A7E',
  'exs': '#6E4A7E',
  'erl': '#B83998',
  
  // Haskell
  'hs': '#5D4F85',
  
  // Clojure
  'clj': '#DB5855',
  
  // F#
  'fs': '#B845FC',
  
  // 默认
  'default': '#8B949E',
};

// 语言名称到颜色的映射（GitHub 语言统计使用）
const LanguageNameColors: Record<string, string> = {
  'javascript': '#F7DF1E',
  'typescript': '#3178C6',
  'python': '#3776AB',
  'java': '#B07219',
  'c++': '#F34B7D',
  'c': '#555555',
  'c#': '#239120',
  'go': '#00ADD8',
  'rust': '#DEA584',
  'kotlin': '#A97BFF',
  'swift': '#FA7343',
  'ruby': '#CC342D',
  'php': '#777BB4',
  'html': '#E34C26',
  'css': '#1572B6',
  'scss': '#C6538C',
  'sass': '#CC6699',
  'less': '#1D365D',
  'shell': '#89E051',
  'powershell': '#012456',
  'dart': '#00B4AB',
  'lua': '#000080',
  'r': '#198CE7',
  'scala': '#C22D40',
  'haskell': '#5D4F85',
  'clojure': '#DB5855',
  'elixir': '#6E4A7E',
  'erlang': '#B83998',
  'f#': '#B845FC',
  'vue': '#4FC08D',
  'react': '#61DAFB',
  'svelte': '#FF3E00',
  'objective-c': '#438EFF',
  'sql': '#E38C00',
  'markdown': '#083FA1',
  'json': '#292929',
  'yaml': '#CB171E',
  'xml': '#E34C26',
  'dockerfile': '#2496ED',
  'makefile': '#427819',
  'cmake': '#064F8C',
  'default': '#8B949E',
};

/**
 * 获取文件扩展名或语言名称对应的颜色
 * @param nameOrExtension 语言名称（如 TypeScript）或文件扩展名（如 ts）
 */
export function getLanguageColor(nameOrExtension: string): string {
  const input = nameOrExtension.toLowerCase().replace('.', '');
  
  // 先尝试按语言名称匹配
  if (LanguageNameColors[input]) {
    return LanguageNameColors[input];
  }
  
  // 再尝试按扩展名匹配
  if (LanguageColors[input]) {
    return LanguageColors[input];
  }
  
  return LanguageColors['default'];
}

// =====================================================
// 图表颜色序列接口
// =====================================================
export interface ChartColorConfig {
  dark: string[];
  light: string[];
}

export const ChartColors: ChartColorConfig = {
  dark: [
    '#3B82F6',  // blue
    '#10B981',  // emerald
    '#F59E0B',  // amber
    '#8B5CF6',  // violet
    '#EC4899',  // pink
    '#06B6D4',  // cyan
    '#EF4444',  // red
    '#84CC16',  // lime
  ],
  light: [
    '#2563EB',  // blue-600
    '#059669',  // emerald-600
    '#D97706',  // amber-600
    '#7C3AED',  // violet-600
    '#DB2777',  // pink-600
    '#0891B2',  // cyan-600
    '#DC2626',  // red-600
    '#65A30D',  // lime-600
  ],
};

// =====================================================
// Diff 颜色接口
// =====================================================
export interface DiffStyleConfig {
  bg: string;
  text: string;
  border: string;
}

export interface DiffThemeConfig {
  added: DiffStyleConfig;
  removed: DiffStyleConfig;
  modified: DiffStyleConfig;
}

export interface DiffColorConfig {
  dark: DiffThemeConfig;
  light: DiffThemeConfig;
}

export const DiffColors: DiffColorConfig = {
  dark: {
    added: {
      bg: 'rgba(16, 185, 129, 0.15)',
      text: '#34D399',
      border: '#10B981',
    },
    removed: {
      bg: 'rgba(239, 68, 68, 0.15)',
      text: '#F87171',
      border: '#EF4444',
    },
    modified: {
      bg: 'rgba(245, 158, 11, 0.15)',
      text: '#FBBF24',
      border: '#F59E0B',
    },
  },
  light: {
    added: {
      bg: 'rgba(16, 185, 129, 0.1)',
      text: '#059669',
      border: '#10B981',
    },
    removed: {
      bg: 'rgba(239, 68, 68, 0.1)',
      text: '#DC2626',
      border: '#EF4444',
    },
    modified: {
      bg: 'rgba(245, 158, 11, 0.1)',
      text: '#D97706',
      border: '#F59E0B',
    },
  },
};
