import {
  LayoutGrid,
  BookOpen,
  Tag,
  CreditCard,
  Flag,
  BarChart2,
  LogOut,
  Plus
} from 'lucide-react';

type IconProps = { className?: string; size?: number; strokeWidth?: number };

export function IconGrid({ className, size = 20, strokeWidth = 1.5 }: IconProps) {
  return <LayoutGrid className={className} size={size} strokeWidth={strokeWidth} />;
}

export function IconLedger({ className, size = 20, strokeWidth = 1.5 }: IconProps) {
  return <BookOpen className={className} size={size} strokeWidth={strokeWidth} />;
}

export function IconTag({ className, size = 20, strokeWidth = 1.5 }: IconProps) {
  return <Tag className={className} size={size} strokeWidth={strokeWidth} />;
}

export function IconCard({ className, size = 20, strokeWidth = 1.5 }: IconProps) {
  return <CreditCard className={className} size={size} strokeWidth={strokeWidth} />;
}

export function IconFlag({ className, size = 20, strokeWidth = 1.5 }: IconProps) {
  return <Flag className={className} size={size} strokeWidth={strokeWidth} />;
}

export function IconChart({ className, size = 20, strokeWidth = 1.5 }: IconProps) {
  return <BarChart2 className={className} size={size} strokeWidth={strokeWidth} />;
}

export function IconLogout({ className, size = 20, strokeWidth = 1.5 }: IconProps) {
  return <LogOut className={className} size={size} strokeWidth={strokeWidth} />;
}

export function IconPlus({ className, size = 20, strokeWidth = 1.5 }: IconProps) {
  return <Plus className={className} size={size} strokeWidth={strokeWidth} />;
}
