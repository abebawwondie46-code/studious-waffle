<!-- edit_profile_dialog.xml -->
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:orientation="vertical"
    android:padding="24dp"
    android:background="#16161E">

    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="Edit Profile"
        android:textColor="#FFFFFF"
        android:textSize="20sp"
        android:textStyle="bold"
        android:layout_marginBottom="20dp" />

    <!-- Profile Image with Camera Badge -->
    <RelativeLayout
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_gravity="center_horizontal"
        android:layout_marginBottom="24dp">

        <de.hdodenhof.circleimageview.CircleImageView
            android:id="@+id/img_dialog_profile"
            android:layout_width="90dp"
            android:layout_height="90dp"
            android:src="@drawable/default_profile"
            android:scaleType="centerCrop" />

        <ImageView
            android:id="@+id/btn_change_photo"
            android:layout_width="32dp"
            android:layout_height="32dp"
            android:layout_alignBottom="@id/img_dialog_profile"
            android:layout_alignEnd="@id/img_dialog_profile"
            android:background="@drawable/bg_camera_badge"
            android:src="@drawable/ic_camera"
            android:padding="6dp"
            android:contentDescription="Change Profile Picture" />
    </RelativeLayout>

    <!-- Username Input -->
    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="Username"
        android:textColor="#8E8E93"
        android:textSize="12sp" />

    <EditText
        android:id="@+id/et_username"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:textColor="#FFFFFF"
        android:textSize="15sp"
        android:backgroundTint="#2C2C38"
        android:singleLine="true"
        android:layout_marginBottom="16dp" />

    <!-- Bio Input -->
    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="Bio"
        android:textColor="#8E8E93"
        android:textSize="12sp" />

    <EditText
        android:id="@+id/et_bio"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:textColor="#FFFFFF"
        android:textSize="15sp"
        android:backgroundTint="#2C2C38"
        android:maxLines="3"
        android:layout_marginBottom="24dp" />

    <!-- Action Buttons -->
    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:gravity="end"
        android:orientation="horizontal">

        <Button
            android:id="@+id/btn_cancel"
            style="?android:attr/borderlessButtonStyle"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="Cancel"
            android:textColor="#FF2A55" />

        <Button
            android:id="@+id/btn_save"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="Save"
            android:textColor="#FFFFFF"
            android:backgroundTint="#FF2A55"
            android:layout_marginStart="12dp" />
    </LinearLayout>
</LinearLayout>
