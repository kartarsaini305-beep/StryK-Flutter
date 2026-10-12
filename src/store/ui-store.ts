import { create } from 'zustand';

type UiState = {
  drawerOpen: boolean;
  currentStreak: number;
  openDrawer: () => void;
  closeDrawer: () => void;
  toggleDrawer: () => void;
};

export const useUiStore = create<UiState>((set) => ({
  drawerOpen: false,
  currentStreak: 0,
  openDrawer: () => set({ drawerOpen: true }),
  closeDrawer: () => set({ drawerOpen: false }),
  toggleDrawer: () => set((state) => ({ drawerOpen: !state.drawerOpen })),
}));
