package com.hazizz.droid.Activities;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Intent;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.support.annotation.NonNull;
import android.support.design.widget.FloatingActionButton;
import android.support.design.widget.NavigationView;
import android.support.v4.app.Fragment;
import android.support.v4.view.GravityCompat;
import android.support.v4.widget.DrawerLayout;
import android.support.v7.app.ActionBarDrawerToggle;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import com.crashlytics.android.Crashlytics;
import com.crashlytics.android.answers.Answers;
import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.firebase.dynamiclinks.FirebaseDynamicLinks;
import com.google.firebase.dynamiclinks.PendingDynamicLinkData;
import com.hazizz.droid.AppInfo;
import com.hazizz.droid.Cache.MeInfo.MeInfo;
import com.hazizz.droid.Communication.POJO.Response.CustomResponseHandler;
import com.hazizz.droid.Communication.POJO.Response.POJOerror;
import com.hazizz.droid.Communication.POJO.Response.POJOme;
import com.hazizz.droid.Communication.POJO.Response.PojoPicSmall;
import com.hazizz.droid.Communication.Requests.GetMyProfilePic;
import com.hazizz.droid.Communication.Requests.JoinGroup;
import com.hazizz.droid.Communication.Requests.Me;
import com.hazizz.droid.Communication.Requests.MessageOfTheDay;
import com.hazizz.droid.Communication.Requests.Parent.Request;
import com.hazizz.droid.Communication.Strings;
import com.hazizz.droid.Converter.Converter;
import com.hazizz.droid.Fragments.GroupTabs.GetGroupMembersFragment;
import com.hazizz.droid.Fragments.GroupTabs.GroupAnnouncementFragment;
import com.hazizz.droid.Fragments.GroupTabs.GroupMainFragment;
import com.hazizz.droid.Fragments.GroupTabs.GroupTabFragment;
import com.hazizz.droid.Fragments.GroupTabs.SubjectsFragment;
import com.hazizz.droid.Fragments.MainTab.GroupsFragment;
import com.hazizz.droid.Fragments.MainTab.MainAnnouncementFragment;
import com.hazizz.droid.Fragments.MainTab.MainFragment;
import com.hazizz.droid.Fragments.MyTasksFragment;
import com.hazizz.droid.Fragments.ViewTaskFragment;
import com.hazizz.droid.Listener.OnBackPressedListener;
import com.hazizz.droid.Manager;
import com.hazizz.droid.Notification.TaskReporterNotification;
import com.hazizz.droid.SharedPrefs;
import com.hazizz.droid.Transactor;
import com.hazizz.droid.Communication.MiddleMan;
import com.hazizz.droid.R;

import io.fabric.sdk.android.Fabric;

public class MainActivity extends AppCompatActivity
        implements NavigationView.OnNavigationItemSelectedListener {

    private static final int PICK_PHOTO_FOR_AVATAR = 1;

    private boolean doubleBackToExitPressedOnce;

    private DrawerLayout drawerLayout;
    private NavigationView navView;
    private ActionBarDrawerToggle toggle;

    private ImageView navProfilePic;
    private TextView navUsername;
    private TextView navEmail;
    private TextView navLogout;

    public static String strNavUsername;
    public static String strNavEmail;
    public static String strNavDisplayName;

    FloatingActionButton fab_joinGroup;
    FloatingActionButton fab_action;

    private Menu menu_nav;
    private MenuItem menuItem_home;
    private MenuItem menuItem_groups;
    private MenuItem menuItem_myTasks;
    private MenuItem menuItem_thera;
    private MenuItem menuItem_settings;
    private MenuItem menuItem_logs;

    private Toolbar toolbar;
    private Fragment currentFrag;

    private Activity thisActivity = this;


    private MeInfo meInfo;

    private OnBackPressedListener currentBackPressedListener;


    public static final String value_INTENT_MODE_VIEWTASK = "viewTask";
    public static final String key_INTENT_MODE = "mode";
    public static final String key_INTENT_GROUPID = "groupId";
    public static final String key_INTENT_TASKID = "taskId";


    private boolean gotMyProfilePicRespond = false;


    private boolean toMainFrag = false;
    CustomResponseHandler rh_profilePic = new CustomResponseHandler() {
        @Override
        public void onPOJOResponse(Object response) {
            Bitmap bitmap = Converter.imageFromText(getBaseContext(),
                    ((PojoPicSmall)response).getData().split(",")[1]);
            bitmap = Converter.scaleBitmapToRegular(bitmap);
            bitmap = Converter.getCroppedBitmap(bitmap);

            meInfo.setProfilePic(Converter.imageToText(bitmap));
            setProfileImageInNav(bitmap);
        }
    };

    CustomResponseHandler responseHandler = new CustomResponseHandler() {
        @Override
        public void onPOJOResponse(Object response) {

            POJOme pojo = (POJOme) response;
            SharedPrefs.save(getApplicationContext(),"userInfo", "username",pojo.getUsername());
            strNavEmail = (pojo.getEmailAddress());
            strNavUsername = (pojo.getUsername());
            strNavDisplayName = (pojo.getDisplayName());
            meInfo.setUserId(pojo.getId());
            meInfo.setProfileName(strNavUsername);
            meInfo.setDisplayName(strNavDisplayName);
            meInfo.setProfileEmail(strNavEmail);
            setDisplayNameInNav(strNavDisplayName);
            navEmail.setText(strNavEmail);
        }
    };

    CustomResponseHandler rh_motd = new CustomResponseHandler() {
        @Override
        public void onPOJOResponse(Object response) {
            String motd = (String)response;
            if(!motd.equals("") && !SharedPrefs.getString(getBaseContext(), "motd", "message").equals(motd)) {
                    AlertDialog.Builder alertDialogBuilder = new AlertDialog.Builder(MainActivity.this);
                    alertDialogBuilder.setTitle("Napi üzenet");
                    alertDialogBuilder
                        .setMessage(motd)
                        .setCancelable(true)
                        .setPositiveButton("Oké", (dialog, id) -> {
                            SharedPrefs.save(getBaseContext(), "motd", "message", motd);
                            dialog.cancel();
                        });
                    AlertDialog alertDialog = alertDialogBuilder.create();
                    alertDialog.show();
            }
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        //if (!BuildConfig.DEBUG) { // only enable bug tracking in release version
        Fabric.with(this, new Crashlytics());
       // }
        Fabric.with(this, new Answers());

        if(!SharedPrefs.Server.hasChangedAddress(this)) {
            SharedPrefs.Server.setMainAddress(this, Request.BASE_URL);
        }

        meInfo = MeInfo.getInstance();


        FirebaseDynamicLinks.getInstance()
                .getDynamicLink(getIntent())
                .addOnSuccessListener(this, new OnSuccessListener<PendingDynamicLinkData>() {
                    @Override
                    public void onSuccess(PendingDynamicLinkData pendingDynamicLinkData) {
                        // Get deep link from result (may be null if no link is found)
                        Uri deepLink = null;
                        if (pendingDynamicLinkData != null) {
                            deepLink = pendingDynamicLinkData.getLink();
                        }

                        if(deepLink!=null){
                            int groupId = Integer.parseInt(deepLink.getQueryParameter("group"));

                                CustomResponseHandler rh_joinGroup = new CustomResponseHandler() {

                                    @Override public void onErrorResponse(POJOerror error) {
                                        if(error.getErrorCode() == 55){ // user already in group
                                            Transactor.fragmentMainGroup(getSupportFragmentManager().beginTransaction(), groupId);
                                            Toast.makeText(thisActivity, getString(R.string.already_in_group),
                                                    Toast.LENGTH_LONG).show();
                                        }
                                    }
                                    @Override public void onSuccessfulResponse() {
                                        Transactor.fragmentMainGroup(getSupportFragmentManager().beginTransaction(), groupId);
                                        Toast.makeText(thisActivity, getString(R.string.added_to_group),
                                                Toast.LENGTH_LONG).show();
                                    }
                                };
                                MiddleMan.newRequest(new JoinGroup(thisActivity, rh_joinGroup, groupId));
                        }

                        Log.e("hey", "dynamic link lol: " + deepLink);
                    }
                })
                .addOnFailureListener(this, new OnFailureListener() {
                    @Override
                    public void onFailure(@NonNull Exception e) {
                        Log.w("hey", "getDynamicLink:onFailure", e);
                    }
                });

        setContentView(R.layout.activity_main);

        Manager.ThreadManager.startThreadIfNotRunning(this);

        toolbar = (Toolbar) findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);

        fab_joinGroup = findViewById(R.id.fab_joinGroup);
        fab_joinGroup.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Transactor.fragmentJoinGroup(getSupportFragmentManager().beginTransaction());
                fab_joinGroup.setVisibility(View.INVISIBLE);
            }
        });
        toMainFrag = true;

        fab_action = (FloatingActionButton) findViewById(R.id.fab_action);
        fab_action.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Log.e("hey", "fab_action CLICKed");
                currentFrag = Transactor.getCurrentFragment(getSupportFragmentManager(), false);

                if (currentFrag instanceof GroupMainFragment) {
                    ((GroupMainFragment)currentFrag).toTaskEditor(getSupportFragmentManager());
                } else if (currentFrag instanceof GroupAnnouncementFragment) {
                    ((GroupAnnouncementFragment)currentFrag).toAnnouncementEditor(getSupportFragmentManager());
                }else if (currentFrag instanceof MainAnnouncementFragment) {
                    toAnnouncementEditorFrag();
                } else if (currentFrag instanceof SubjectsFragment) {
                    ((SubjectsFragment)currentFrag).toCreateSubject(getSupportFragmentManager());
                } else if (currentFrag instanceof MainFragment) {
                    toCreateTaskFrag();
                } else if (currentFrag instanceof GroupsFragment) {
                    ((GroupsFragment)currentFrag).toCreateGroup(getSupportFragmentManager());
                }else if (currentFrag instanceof MyTasksFragment) {
                    ((MyTasksFragment)currentFrag).toCreateTask();
                }else if (currentFrag instanceof GetGroupMembersFragment) {
                    ((GetGroupMembersFragment)currentFrag).openInviteLinkDialog(getSupportFragmentManager());
                }
            }
        });
        navView = (NavigationView) findViewById(R.id.nav_view);

        navView.setNavigationItemSelectedListener(this);
        navView.bringToFront();

        View headerView = navView.getHeaderView(0);
        navProfilePic = (ImageView) headerView.findViewById(R.id.imageView_memberProfilePic);
        navUsername = (TextView) headerView.findViewById(R.id.textView_name);
        navEmail = (TextView) headerView.findViewById(R.id.textView_email);
        navLogout = findViewById(R.id.textView_logout);

        menu_nav = navView.getMenu();
        menuItem_home     = menu_nav.getItem(0);
        menuItem_groups   = menu_nav.getItem(1);
        menuItem_myTasks  = menu_nav.getItem(2);
        menuItem_thera    = menu_nav.getItem(3);
        menuItem_settings = menu_nav.getItem(4);
        menuItem_logs     = menu_nav.getItem(5);


        drawerLayout = findViewById(R.id.drawer_layout);
        drawerLayout.addDrawerListener(new DrawerLayout.DrawerListener() {
            @Override
            public void onDrawerSlide(@NonNull View drawerView, float slideOffset) {

            }

            @Override
            public void onDrawerOpened(@NonNull View drawerView) {
                if(!gotMyProfilePicRespond){
                    MiddleMan.newRequest(new Me(thisActivity, responseHandler));
                    MiddleMan.newRequest(new GetMyProfilePic(thisActivity, rh_profilePic));
                }
            }

            @Override
            public void onDrawerClosed(@NonNull View drawerView) {

            }

            @Override
            public void onDrawerStateChanged(int newState) {

            }
        });
        toggle = new ActionBarDrawerToggle(this, drawerLayout, R.string.open, R.string.close);
        drawerLayout.addDrawerListener(toggle);
        toggle.syncState();

        getSupportActionBar().setDisplayHomeAsUpEnabled(true);

        Activity thisActivity = this;

        navLogout.setOnClickListener(new View.OnClickListener() {
             @Override
             public void onClick(View view) {
                 SharedPrefs.savePref(getBaseContext(), "autoLogin", "autoLogin", false);
                 SharedPrefs.TokenManager.invalidateTokens(getBaseContext());
                 SharedPrefs.ThSessionManager.clearSession(getBaseContext());
                 SharedPrefs.ThLoginData.clearAllData(getBaseContext());
                 Intent i = new Intent(thisActivity, AuthActivity.class);
                 finish();
                 startActivity(i);
             }
        });

        MiddleMan.newRequest(new MessageOfTheDay(this, rh_motd));

        if(AppInfo.isFirstTimeLaunched(getBaseContext())){
            TaskReporterNotification.enable(getBaseContext());
            TaskReporterNotification.setScheduleForNotification(getBaseContext(), 17, 0);
        }



        Intent intent = getIntent();
        String mode = intent.getStringExtra("mode");
        if(mode != null && mode.equals(value_INTENT_MODE_VIEWTASK)){
            long groupId = intent.getLongExtra(key_INTENT_GROUPID, 0);
            long taskId = intent.getLongExtra(key_INTENT_TASKID, 0);
            if(groupId != 0){
                Transactor.fragmentViewTask(getSupportFragmentManager().beginTransaction(), (int)taskId,
                        true, Strings.Dest.TOMAIN, ViewTaskFragment.publicMode);
            }else{
                Transactor.fragmentViewTask(getSupportFragmentManager().beginTransaction(), (int)taskId,
                        true, Strings.Dest.TOMAIN, ViewTaskFragment.myMode);
            }
        }
    }

    @Override
    public void onResume() {
        super.onResume();
        invalidateOptionsMenu();
        Log.e("hey", "onResume is trigered");
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        Log.e("hey", "onCreateOptionsMenu asdasd");

        if(Manager.WidgetManager.getDest() == Manager.WidgetManager.TOATCHOOSER){
            Transactor.fragmentATChooser(getSupportFragmentManager().beginTransaction());
            Log.e("hey", "TOATCHOOSER hah");
        }
        else if(toMainFrag) {
            toMainFrag();
            toMainFrag = false;
        }
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        Fragment cFrag = Transactor.getCurrentFragment(getSupportFragmentManager(), false);
        if(toggle.onOptionsItemSelected(item)){
            return true;
        }
        switch (item.getItemId()){
            case R.id.action_leaveGroup:
                ((GroupTabFragment)cFrag).leaveGroup();
                return true;
            case R.id.action_profilePic:
                pickImage();
                return true;
            case R.id.action_feedback:
                Transactor.feedbackActivity(this);
                return true;
            case R.id.action_settings:
                Transactor.fragmentOptions(getSupportFragmentManager().beginTransaction());
                return true;
        }
        return super.onOptionsItemSelected(item);
    }

    @SuppressWarnings("StatementWithEmptyBody")
    @Override
    public boolean onNavigationItemSelected(MenuItem item) {
        currentFrag = Transactor.getCurrentFragment(getSupportFragmentManager(), false);
        switch (item.getItemId()) {
            case R.id.nav_home:
                toMainFrag();
                break;
            case R.id.nav_groups:
                toGroupsFrag();
                break;
            case R.id.nav_mytasks:
                Transactor.fragmentMyTasks(getSupportFragmentManager().beginTransaction());
                break;
            case R.id.nav_thera:
                Transactor.fragmentThMain(getSupportFragmentManager().beginTransaction());
                break;
            case R.id.nav_settings:
                Transactor.fragmentOptions(getSupportFragmentManager().beginTransaction());
                break;
            case R.id.nav_feedback:
                Transactor.feedbackActivity(this);
                break;
            case R.id.nav_logs:
                Transactor.fragmentLogs(getSupportFragmentManager().beginTransaction());
                break;

        }
        DrawerLayout drawer = (DrawerLayout) findViewById(R.id.drawer_layout);
        drawer.closeDrawer(GravityCompat.START);
        return true;
    }
    void toGroupsFrag(){
        Transactor.fragmentGroups(getSupportFragmentManager().beginTransaction());
    }
    void toMainFrag(){
        Transactor.fragmentMain(getSupportFragmentManager().beginTransaction());
    }

    void toCreateTaskFrag(){
        Transactor.fragmentCreatorAT(getSupportFragmentManager().beginTransaction(), GroupsFragment.Dest.TOCREATETASK);

    }
    void toAnnouncementEditorFrag(){
        Transactor.fragmentCreatorAT(getSupportFragmentManager().beginTransaction(), GroupsFragment.Dest.TOCREATEANNOUNCEMET);

    }

    public void setOnBackPressedListener(OnBackPressedListener listener){
        currentBackPressedListener = listener;
    }

    public void removeOnBackPressedListener(){
        currentBackPressedListener = null;
    }

    @Override
    public void onBackPressed() {
        Fragment currentFrag = Transactor.getCurrentFragment(getSupportFragmentManager(), false);
        if(currentFrag instanceof MainFragment || currentFrag instanceof MainAnnouncementFragment){
            if (doubleBackToExitPressedOnce) {
                // close application
                if(android.os.Build.VERSION.SDK_INT >= 21){
                    finishAndRemoveTask();
                } else {
                    finish();
                }
                return;
            }
            this.doubleBackToExitPressedOnce = true;
            Toast.makeText(this, R.string.press_again_to_exit, Toast.LENGTH_SHORT).show();

            new Handler().postDelayed(new Runnable() {
                @Override public void run() {
                    doubleBackToExitPressedOnce=false;
                }
            }, 2000);
        }
        else if(currentBackPressedListener != null){
            currentBackPressedListener.onBackPressed();
            return;
        }else{
            Transactor.fragmentMain(getSupportFragmentManager().beginTransaction());
        }
    }

    public void hideFabs(){
        fab_action.setVisibility(View.INVISIBLE);
        fab_joinGroup.setVisibility(View.INVISIBLE);
    }

    public void onFragmentCreated(){
        currentFrag = Transactor.getCurrentFragment(getSupportFragmentManager(), false);

        if (currentFrag instanceof GroupAnnouncementFragment || currentFrag instanceof GroupMainFragment
            || currentFrag instanceof MainAnnouncementFragment || currentFrag instanceof MainFragment
            || currentFrag instanceof MyTasksFragment ) {
            fab_action.setVisibility(View.VISIBLE);
                if (currentFrag instanceof MainFragment) {
                    navView.getMenu().getItem(0).setChecked(true);
                } else {
                    navView.getMenu().getItem(0).setChecked(false);
                }
        } else {
            fab_action.setVisibility(View.INVISIBLE);
        }
        if (currentFrag instanceof GroupsFragment) {
            fab_joinGroup.setVisibility(View.VISIBLE);
            navView.getMenu().getItem(1).setChecked(true);
            fab_action.setVisibility(View.VISIBLE);
        } else {
            fab_joinGroup.setVisibility(View.INVISIBLE);
            navView.getMenu().getItem(1).setChecked(false);
        }
    }

    public void onTabSelected(Fragment currentFrag){
            if (currentFrag instanceof GroupAnnouncementFragment || currentFrag instanceof GroupMainFragment
                    || currentFrag instanceof MainAnnouncementFragment || currentFrag instanceof SubjectsFragment
                    || currentFrag instanceof MainFragment || currentFrag instanceof GroupsFragment
                    || currentFrag instanceof GetGroupMembersFragment) {
                fab_action.setVisibility(View.VISIBLE);
                if (currentFrag instanceof GroupsFragment) {
                    fab_joinGroup.setVisibility(View.VISIBLE);
                    navView.getMenu().getItem(1).setChecked(true);
                } else {
                    fab_joinGroup.setVisibility(View.INVISIBLE);
                    navView.getMenu().getItem(1).setChecked(false);
                }
                if (currentFrag instanceof MainFragment) {
                    navView.getMenu().getItem(0).setChecked(true);
                } else {
                    navView.getMenu().getItem(0).setChecked(false);
                }
            } else {
                fab_action.setVisibility(View.INVISIBLE);
            }
    }
    public void pickImage() {
        Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
        intent.setType("image/*");
        startActivityForResult(intent, PICK_PHOTO_FOR_AVATAR);
    }

    public void setProfileImageInNav(Bitmap bitmap){
        navProfilePic.setImageBitmap(bitmap);
    }

    public void setDisplayNameInNav(String newDisplayName){
        navUsername.setText(newDisplayName);
    }

    public void activateHiddenFeatures(){
        menuItem_thera.setVisible(true);
        menuItem_logs.setVisible(true);
    }
}