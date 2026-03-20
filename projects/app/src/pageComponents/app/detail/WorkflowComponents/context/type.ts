import type { AppChatConfigType } from '@fastgpt/global/core/app/type';
import type { Node, Edge } from 'reactflow';

export type WorkflowStateType = {
  nodes: Node[];
  edges: Edge[];
  chatConfig: AppChatConfigType;
};
