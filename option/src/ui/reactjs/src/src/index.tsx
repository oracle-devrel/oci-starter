import * as React from 'react';
import ReactDOM from 'react-dom/client';
import { StyledEngineProvider } from '@mui/material/styles';
import Starter from './starter';

ReactDOM.createRoot(document.querySelector("#root") as HTMLElement).render(
  <React.StrictMode>
    <StyledEngineProvider injectFirst>
      <Starter />
    </StyledEngineProvider>
  </React.StrictMode>
) ;