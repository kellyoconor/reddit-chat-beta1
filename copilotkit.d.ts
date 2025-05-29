import React from 'react';

declare module '@copilotkit/react-core' {
  export interface CopilotKitProps {
    runtimeUrl: string;
    children: React.ReactNode;
  }

  export function CopilotKit(props: CopilotKitProps): JSX.Element;
}

declare module '@copilotkit/react-ui' {
  export interface CopilotChatLabels {
    title?: string;
    initial?: string;
  }

  export interface CopilotChatProps {
    instructions?: string;
    labels?: CopilotChatLabels;
  }

  export function CopilotChat(props: CopilotChatProps): JSX.Element;
}

declare module '@copilotkit/react-ui/styles.css'; 