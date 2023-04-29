<?php
-- From frity-creds: Use creds.js; --

class --Name-- {
	public static function Start($attributes = []) { return function (
		
	) use ($attributes) { ?>
		<?php 
			attributes_extract($attributes, 'class', $class);
			attributes($attributes);
		?>

		<div class="--na-me-- <?= $class ?>" <?= $attributes ?>>
	<?php }; }

	public static function End() { ?>
		</div>
	<?php }
}
