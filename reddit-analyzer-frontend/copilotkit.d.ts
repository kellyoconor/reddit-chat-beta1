declare module '@copilotkit/react-core' {
  export const CopilotKit: React.FC<{
    children: React.ReactNode;
    runtimeUrl: string;
  }>;
}

declare module '@copilotkit/react-ui' {
  export const CopilotChat: React.FC<{
    instructions?: string;
    labels?: {
      title?: string;
      initial?: string;
    };
  }>;
}

declare module '@copilotkit/react-ui/styles.css' {
  const styles: any;
  export default styles;
} 