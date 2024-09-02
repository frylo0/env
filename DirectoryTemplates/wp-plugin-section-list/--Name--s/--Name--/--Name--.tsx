import s from "./--Name--.module.scss";
import cn from "classnames";

import { Image, TMedia } from "../../../common/Image/Image";
import { ItemProps } from "../../../common/List/List";
import { PlainText } from "../../../common/PlainText/PlainText";

export type T--Name-- = {
	image: TMedia;
	label: string;
	url: string;
};

interface --Name--Props extends ItemProps<T--Name--> {
	className?: string;
}

export const --Name--: React.FC<--Name--Props> = ({
	className = "",
	props,
	setProps,
}) => {
	const { image, label, url } = props;

	const handleImageChange = (value: TMedia) => {
		setProps({
			...props,
			image: value,
		});
	};
	const handleLabelChange = (value: string) => {
		setProps({
			...props,
			label: value,
		});
	};
	const handleUrlChange = (value: string) => {
		setProps({
			...props,
			url: value,
		});
	};

	return (
		<>
			<Image
				label="Лого клиента"
				value={image}
				onChange={handleImageChange}
				restrictions={{
					aspectRatio: {
						check: (width, height) => width === height,
						expectedValue: "квадратное изображение",
					},
					maxWeight: '300KB',
				}}
			/>
			<PlainText
				label="Название клиента"
				value={label}
				onChange={handleLabelChange}
				restrictions={{
					minLength: 5,
					maxLength: 30,
				}}
			/>
			<PlainText
				label="Ссылка на сайт клиента"
				value={url}
				onChange={handleUrlChange}
			/>
		</>
	);
};
