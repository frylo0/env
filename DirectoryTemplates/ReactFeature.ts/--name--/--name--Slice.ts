import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { RootState } from '../../app/store';
import { fetch--Name-- } from './--name--API';

export interface --Name--State {
   %option: %type,
}

const initialState: --Name--State = {
   %option: %value,
};

export const --name--Slice = createSlice({
   name: '--name--',
   initialState,
   reducers: {

   },
});

export const {  } = --name--Slice.actions;
export const select%option = (state: RootState) => state.--name--.%option;
export default --name--Slice.reducer;
