import { PHASE_PRODUCTION_BUILD } from 'next/constants';

export default async (phase : any) => {
  if (phase === PHASE_PRODUCTION_BUILD) {
    return {
      // output: 'export'
    }
  }
 
  return {

  }
};