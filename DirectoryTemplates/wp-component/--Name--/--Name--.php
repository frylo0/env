<?php
-- From frity-creds: Use ./creds.js; --
?>

<?php
function --Name-- ($attributes = []) { return function (
	
) use ($attributes) { ?>
	<?php 
		attributes_extract($attributes, 'class', $class);
		attributes($attributes);
	?>

	<div class="--na-me-- <?= $class ?>" <?= $attributes ?>>
        
    </div>
<?php }; } ?>
