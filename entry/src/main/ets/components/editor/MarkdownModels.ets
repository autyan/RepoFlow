/**
 * RepoFlow 富文本编辑器数据模型
 */

/**
 * Markdown 节点类型
 */
export enum MarkdownNodeType {
  TEXT = 'text',
  HEADING1 = 'heading1',
  HEADING2 = 'heading2',
  HEADING3 = 'heading3',
  HEADING4 = 'heading4',
  HEADING5 = 'heading5',
  HEADING6 = 'heading6',
  PARAGRAPH = 'paragraph',
  BOLD = 'bold',
  ITALIC = 'italic',
  STRIKETHROUGH = 'strikethrough',
  CODE = 'code',
  CODE_BLOCK = 'code_block',
  LINK = 'link',
  IMAGE = 'image',
  BLOCKQUOTE = 'blockquote',
  UNORDERED_LIST = 'unordered_list',
  ORDERED_LIST = 'ordered_list',
  LIST_ITEM = 'list_item',
  HORIZONTAL_RULE = 'horizontal_rule',
  LINE_BREAK = 'line_break',
  TABLE = 'table',
  TABLE_ROW = 'table_row',
  TABLE_CELL = 'table_cell',
}

/**
 * Markdown 节点
 */
export interface MarkdownNode {
  type: MarkdownNodeType;
  content?: string;
  children?: MarkdownNode[];
  attributes?: Record<string, string>;
  // 链接和图片属性
  url?: string;
  title?: string;
  alt?: string;
  // 代码块属性
  language?: string;
  // 列表属性
  ordered?: boolean;
  start?: number;
  // 表格属性
  align?: ('left' | 'center' | 'right')[];
  isHeader?: boolean;
}

/**
 * 编辑器模式
 */
export enum EditorMode {
  EDIT = 'edit',
  PREVIEW = 'preview',
  SPLIT = 'split',
}

/**
 * 工具栏按钮类型
 */
export enum ToolbarAction {
  HEADING1 = 'heading1',
  HEADING2 = 'heading2',
  HEADING3 = 'heading3',
  BOLD = 'bold',
  ITALIC = 'italic',
  STRIKETHROUGH = 'strikethrough',
  CODE = 'code',
  CODE_BLOCK = 'code_block',
  LINK = 'link',
  IMAGE = 'image',
  QUOTE = 'quote',
  UNORDERED_LIST = 'unordered_list',
  ORDERED_LIST = 'ordered_list',
  HORIZONTAL_RULE = 'horizontal_rule',
  TABLE = 'table',
  UNDO = 'undo',
  REDO = 'redo',
}

/**
 * 光标选区
 */
export interface EditorSelection {
  start: number;
  end: number;
  text: string;
}

/**
 * 编辑器状态
 */
export interface EditorState {
  content: string;
  selection: EditorSelection;
  mode: EditorMode;
  undoStack: string[];
  redoStack: string[];
  isDirty: boolean;
}

/**
 * Markdown语法结果接口
 */
export interface MarkdownSyntaxResult {
  prefix: string;
  suffix: string;
  placeholder: string;
  cursorOffset: number;
}

/**
 * 获取工具栏按钮的Markdown语法
 */
export function getMarkdownSyntax(action: ToolbarAction, selection: string = ''): MarkdownSyntaxResult {
  switch (action) {
    case ToolbarAction.HEADING1:
      return { prefix: '# ', suffix: '', placeholder: '标题', cursorOffset: 2 } as MarkdownSyntaxResult;
    case ToolbarAction.HEADING2:
      return { prefix: '## ', suffix: '', placeholder: '标题', cursorOffset: 3 } as MarkdownSyntaxResult;
    case ToolbarAction.HEADING3:
      return { prefix: '### ', suffix: '', placeholder: '标题', cursorOffset: 4 } as MarkdownSyntaxResult;
    case ToolbarAction.BOLD:
      return { prefix: '**', suffix: '**', placeholder: '粗体文本', cursorOffset: 2 } as MarkdownSyntaxResult;
    case ToolbarAction.ITALIC:
      return { prefix: '*', suffix: '*', placeholder: '斜体文本', cursorOffset: 1 } as MarkdownSyntaxResult;
    case ToolbarAction.STRIKETHROUGH:
      return { prefix: '~~', suffix: '~~', placeholder: '删除线文本', cursorOffset: 2 } as MarkdownSyntaxResult;
    case ToolbarAction.CODE:
      return { prefix: '`', suffix: '`', placeholder: '代码', cursorOffset: 1 } as MarkdownSyntaxResult;
    case ToolbarAction.CODE_BLOCK:
      return { prefix: '```\n', suffix: '\n```', placeholder: '代码块', cursorOffset: 4 } as MarkdownSyntaxResult;
    case ToolbarAction.LINK:
      return {
        prefix: '[',
        suffix: '](url)',
        placeholder: selection || '链接文本',
        cursorOffset: selection ? selection.length + 3 : 1
      } as MarkdownSyntaxResult;
    case ToolbarAction.IMAGE:
      return { prefix: '![', suffix: '](url)', placeholder: '图片描述', cursorOffset: 2 } as MarkdownSyntaxResult;
    case ToolbarAction.QUOTE:
      return { prefix: '> ', suffix: '', placeholder: '引用文本', cursorOffset: 2 } as MarkdownSyntaxResult;
    case ToolbarAction.UNORDERED_LIST:
      return { prefix: '- ', suffix: '', placeholder: '列表项', cursorOffset: 2 } as MarkdownSyntaxResult;
    case ToolbarAction.ORDERED_LIST:
      return { prefix: '1. ', suffix: '', placeholder: '列表项', cursorOffset: 3 } as MarkdownSyntaxResult;
    case ToolbarAction.HORIZONTAL_RULE:
      return { prefix: '\n---\n', suffix: '', placeholder: '', cursorOffset: 5 } as MarkdownSyntaxResult;
    case ToolbarAction.TABLE:
      return {
        prefix: '| 列1 | 列2 | 列3 |\n| --- | --- | --- |\n| ',
        suffix: ' |  |  |',
        placeholder: '内容',
        cursorOffset: 42
      } as MarkdownSyntaxResult;
    default:
      return { prefix: '', suffix: '', placeholder: '', cursorOffset: 0 } as MarkdownSyntaxResult;
  }
}

/**
 * 检测当前行的Markdown类型
 */
export function detectLineType(line: string): MarkdownNodeType {
  const trimmed = line.trim();

  if (trimmed.startsWith('# ')) return MarkdownNodeType.HEADING1;
  if (trimmed.startsWith('## ')) return MarkdownNodeType.HEADING2;
  if (trimmed.startsWith('### ')) return MarkdownNodeType.HEADING3;
  if (trimmed.startsWith('#### ')) return MarkdownNodeType.HEADING4;
  if (trimmed.startsWith('##### ')) return MarkdownNodeType.HEADING5;
  if (trimmed.startsWith('###### ')) return MarkdownNodeType.HEADING6;
  if (trimmed.startsWith('> ')) return MarkdownNodeType.BLOCKQUOTE;
  if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) return MarkdownNodeType.UNORDERED_LIST;
  if (/^\d+\.\s/.test(trimmed)) return MarkdownNodeType.ORDERED_LIST;
  if (trimmed.startsWith('```')) return MarkdownNodeType.CODE_BLOCK;
  if (trimmed === '---' || trimmed === '***' || trimmed === '___') {
    return MarkdownNodeType.HORIZONTAL_RULE;
  }
  if (trimmed.startsWith('|') && trimmed.endsWith('|')) return MarkdownNodeType.TABLE;

  return MarkdownNodeType.PARAGRAPH;
}

/**
 * 行内Markdown模式接口
 */
interface InlineMarkdownPattern {
  regex: RegExp;
  type: MarkdownNodeType;
  extract: (m: RegExpExecArray) => MarkdownNode;
}

/**
 * 匹配结果接口
 */
interface EarliestMatch {
  index: number;
  length: number;
  node: MarkdownNode;
}

/**
 * 解析行内Markdown语法
 */
export function parseInlineMarkdown(text: string): MarkdownNode[] {
  const nodes: MarkdownNode[] = [];
  let remaining = text;

  // 简化的解析器，处理常见语法
  const patterns: InlineMarkdownPattern[] = [
    {
      regex: /\*\*(.+?)\*\*/,
      type: MarkdownNodeType.BOLD,
      extract: (m) => ({ type: MarkdownNodeType.BOLD, content: m[1] })
    },
    {
      regex: /\*(.+?)\*/,
      type: MarkdownNodeType.ITALIC,
      extract: (m) => ({ type: MarkdownNodeType.ITALIC, content: m[1] })
    },
    {
      regex: /~~(.+?)~~/,
      type: MarkdownNodeType.STRIKETHROUGH,
      extract: (m) => ({ type: MarkdownNodeType.STRIKETHROUGH, content: m[1] })
    },
    {
      regex: /`(.+?)`/,
      type: MarkdownNodeType.CODE,
      extract: (m) => ({ type: MarkdownNodeType.CODE, content: m[1] })
    },
    {
      regex: /\[(.+?)\]\((.+?)\)/,
      type: MarkdownNodeType.LINK,
      extract: (m) => ({ type: MarkdownNodeType.LINK, content: m[1], url: m[2] })
    },
    {
      regex: /!\[(.+?)\]\((.+?)\)/,
      type: MarkdownNodeType.IMAGE,
      extract: (m) => ({ type: MarkdownNodeType.IMAGE, alt: m[1], url: m[2] })
    },
  ];

  while (remaining.length > 0) {
    let earliest: EarliestMatch | null = null;

    for (const pattern of patterns) {
      const match = pattern.regex.exec(remaining);
      if (match && (earliest === null || match.index < earliest.index)) {
        earliest = {
          index: match.index,
          length: match[0].length,
          node: pattern.extract(match)
        };
      }
    }

    if (earliest && earliest.index < remaining.length) {
      // 添加匹配前的纯文本
      if (earliest.index > 0) {
        nodes.push({
          type: MarkdownNodeType.TEXT,
          content: remaining.substring(0, earliest.index)
        });
      }
      // 添加匹配的节点
      nodes.push(earliest.node);
      remaining = remaining.substring(earliest.index + earliest.length);
    } else {
      // 没有匹配，添加剩余文本
      if (remaining.length > 0) {
        nodes.push({
          type: MarkdownNodeType.TEXT,
          content: remaining
        });
      }
      break;
    }
  }

  return nodes;
}

/**
 * Markdown解析器
 */
export class MarkdownParser {
  /**
   * 解析Markdown文本为节点树
   */
  static parse(markdown: string): MarkdownNode[] {
    const lines = markdown.split('\n');
    const nodes: MarkdownNode[] = [];
    let i = 0;

    while (i < lines.length) {
      const line = lines[i];
      const lineType = detectLineType(line);

      switch (lineType) {
        case MarkdownNodeType.HEADING1:
        case MarkdownNodeType.HEADING2:
        case MarkdownNodeType.HEADING3:
        case MarkdownNodeType.HEADING4:
        case MarkdownNodeType.HEADING5:
        case MarkdownNodeType.HEADING6: {
          const level = line.match(/^#+/)?.[0].length ?? 1;
          const content = line.replace(/^#+\s*/, '');
          nodes.push({
            type: lineType,
            content,
            children: parseInlineMarkdown(content)
          });
          i++;
          break;
        }

        case MarkdownNodeType.CODE_BLOCK: {
          const language = line.replace('```', '').trim();
          const codeLines: string[] = [];
          i++;
          while (i < lines.length && !lines[i].startsWith('```')) {
            codeLines.push(lines[i]);
            i++;
          }
          nodes.push({
            type: MarkdownNodeType.CODE_BLOCK,
            content: codeLines.join('\n'),
            language
          });
          i++; // 跳过结束的```
          break;
        }

        case MarkdownNodeType.BLOCKQUOTE: {
          const quoteLines: string[] = [];
          while (i < lines.length && lines[i].trim().startsWith('>')) {
            quoteLines.push(lines[i].replace(/^>\s?/, ''));
            i++;
          }
          nodes.push({
            type: MarkdownNodeType.BLOCKQUOTE,
            content: quoteLines.join('\n'),
            children: MarkdownParser.parse(quoteLines.join('\n'))
          });
          break;
        }

        case MarkdownNodeType.UNORDERED_LIST: {
          const listItems: MarkdownNode[] = [];
          while (i < lines.length && (lines[i].trim().startsWith('- ') || lines[i].trim().startsWith('* '))) {
            const content = lines[i].replace(/^[\s]*[-*]\s/, '');
            listItems.push({
              type: MarkdownNodeType.LIST_ITEM,
              content,
              children: parseInlineMarkdown(content)
            });
            i++;
          }
          nodes.push({
            type: MarkdownNodeType.UNORDERED_LIST,
            children: listItems
          });
          break;
        }

        case MarkdownNodeType.ORDERED_LIST: {
          const listItems: MarkdownNode[] = [];
          let start = parseInt(line.match(/^(\d+)\./)?.[1] ?? '1');
          while (i < lines.length && /^\d+\.\s/.test(lines[i].trim())) {
            const content = lines[i].replace(/^\s*\d+\.\s/, '');
            listItems.push({
              type: MarkdownNodeType.LIST_ITEM,
              content,
              children: parseInlineMarkdown(content)
            });
            i++;
          }
          nodes.push({
            type: MarkdownNodeType.ORDERED_LIST,
            children: listItems,
            start
          });
          break;
        }

        case MarkdownNodeType.HORIZONTAL_RULE: {
          nodes.push({ type: MarkdownNodeType.HORIZONTAL_RULE });
          i++;
          break;
        }

        case MarkdownNodeType.TABLE: {
          const tableRows: MarkdownNode[] = [];
          let alignRow: string | null = null;

          while (i < lines.length && lines[i].includes('|')) {
            const row = lines[i];
            // 检测对齐行
            if (row.match(/^\|[\s\-:|]+\|$/)) {
              alignRow = row;
              i++;
              continue;
            }

            const cells = row.split('|')
              .filter((c, idx, arr) => idx > 0 && idx < arr.length - 1)
              .map(c => ({
                type: MarkdownNodeType.TABLE_CELL,
                content: c.trim(),
                children: parseInlineMarkdown(c.trim())
              } as MarkdownNode));

            tableRows.push({
              type: MarkdownNodeType.TABLE_ROW,
              children: cells,
              isHeader: tableRows.length === 0
            });
            i++;
          }

          nodes.push({
            type: MarkdownNodeType.TABLE,
            children: tableRows
          });
          break;
        }

        case MarkdownNodeType.PARAGRAPH:
        default: {
          if (line.trim() === '') {
            i++;
            break;
          }
          // 收集连续的段落行
          const paraLines: string[] = [line];
          i++;
          while (i < lines.length &&
            lines[i].trim() !== '' &&
            detectLineType(lines[i]) === MarkdownNodeType.PARAGRAPH) {
            paraLines.push(lines[i]);
            i++;
          }
          const content = paraLines.join('\n');
          nodes.push({
            type: MarkdownNodeType.PARAGRAPH,
            content,
            children: parseInlineMarkdown(content)
          });
          break;
        }
      }
    }

    return nodes;
  }

  /**
   * 将节点树转换回Markdown文本
   */
  static stringify(nodes: MarkdownNode[]): string {
    return nodes.map(node => {
      switch (node.type) {
        case MarkdownNodeType.HEADING1:
          return `# ${node.content}`;
        case MarkdownNodeType.HEADING2:
          return `## ${node.content}`;
        case MarkdownNodeType.HEADING3:
          return `### ${node.content}`;
        case MarkdownNodeType.HEADING4:
          return `#### ${node.content}`;
        case MarkdownNodeType.HEADING5:
          return `##### ${node.content}`;
        case MarkdownNodeType.HEADING6:
          return `###### ${node.content}`;
        case MarkdownNodeType.CODE_BLOCK:
          return `\`\`\`${node.language || ''}\n${node.content}\n\`\`\``;
        case MarkdownNodeType.BLOCKQUOTE:
          return node.content?.split('\n').map(l => `> ${l}`).join('\n') ?? '';
        case MarkdownNodeType.UNORDERED_LIST:
          return node.children?.map(c => `- ${c.content}`).join('\n') ?? '';
        case MarkdownNodeType.ORDERED_LIST:
          return node.children?.map((c, i) => `${(node.start ?? 1) + i}. ${c.content}`).join('\n') ?? '';
        case MarkdownNodeType.HORIZONTAL_RULE:
          return '---';
        case MarkdownNodeType.PARAGRAPH:
          return node.content ?? '';
        default:
          return node.content ?? '';
      }
    }).join('\n\n');
  }
}
