import s from "./--Name--.module.scss";
import cn from "classnames";

interface --Name--Props {
	className?: string;
}

export const --Name--: React.FC<--Name--Props> = ({
	className = "",
}) => {
	return (
		<div className={cn(s["--naMe--"], className)}>
			
		</div>
	);
};
