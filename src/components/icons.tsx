import Svg, { Path, type SvgProps } from 'react-native-svg';

export function ShareIcon({ color = '#FFFFFF', size = 22, ...props }: SvgProps & { size?: number }) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none" accessibilityElementsHidden {...props}>
      <Path
        d="M4 12v7a1 1 0 0 0 1 1h14a1 1 0 0 0 1-1v-7M16 8l-4-4-4 4M12 4v13"
        stroke={color}
        strokeWidth={1.8}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  );
}

export function HomeIcon({ color = '#FFFFFF', size = 22 }: { color?: string; size?: number }) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M4 10.5 12 4l8 6.5V20a1 1 0 0 1-1 1h-5v-6H10v6H5a1 1 0 0 1-1-1v-9.5Z"
        stroke={color}
        strokeWidth={1.8}
        strokeLinejoin="round"
      />
    </Svg>
  );
}

export function FlameIcon({ color = '#F5BD6E', size = 22 }: { color?: string; size?: number }) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M12 3s2.2 3.2 2.2 5.6c0 1.2-.5 2.2-1.3 2.9 1.9-.2 4.6-1.8 5.6-4.7 1.8 3 1.9 6.7-.2 9.3C16.6 18.8 14.5 20 12 20s-4.6-1.2-6.3-3.9C3.6 13.5 3.7 9.8 5.5 6.8c1 2.9 3.7 4.5 5.6 4.7-.8-.7-1.3-1.7-1.3-2.9C9.8 6.2 12 3 12 3Z"
        fill={color}
      />
    </Svg>
  );
}

export function CalendarIcon({ color = '#FFFFFF', size = 22 }: { color?: string; size?: number }) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M7 4v3M17 4v3M4.5 9h15M6 7h12a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2Z"
        stroke={color}
        strokeWidth={1.8}
        strokeLinecap="round"
      />
    </Svg>
  );
}

export function MapPinIcon({ color = '#FFFFFF', size = 22 }: { color?: string; size?: number }) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M12 21s7-5.4 7-11a7 7 0 1 0-14 0c0 5.6 7 11 7 11Z"
        stroke={color}
        strokeWidth={1.8}
      />
      <Path d="M12 10.5a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3Z" fill={color} />
    </Svg>
  );
}

export function UserIcon({ color = '#FFFFFF', size = 22 }: { color?: string; size?: number }) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M12 12a4 4 0 1 0-4-4 4 4 0 0 0 4 4ZM6 20a6 6 0 0 1 12 0"
        stroke={color}
        strokeWidth={1.8}
        strokeLinecap="round"
      />
    </Svg>
  );
}

export function LogoutIcon({ color = '#E5645F', size = 22 }: { color?: string; size?: number }) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M10 17H6a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2h4M14 16l4-4-4-4M18 12H9"
        stroke={color}
        strokeWidth={1.8}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  );
}
