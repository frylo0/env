import styles from './--Name--.module.scss';
import { classNameResolver } from 'react-class-name-resolver';
const cn = classNameResolver(styles);

export function --Name--({
   className,
}) {
   return (
      <div className={cn`--na-me--` + className}>

      </div>
   );
}